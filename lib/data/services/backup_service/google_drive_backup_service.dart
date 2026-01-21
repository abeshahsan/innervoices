import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/models/backup_info.dart';

class GoogleDriveBackupService {
  final GoogleSignIn googleSignIn;
  static const String _backupFileName = 'inner_voices_backup.enc';
  static const String _metadataFileName = 'inner_voices_backup_meta.json';

  GoogleDriveBackupService({required this.googleSignIn});

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // Get authorization for Drive scope using the auth service
      final GoogleSignInClientAuthorization? authorization =
          await GoogleAuthService.instance.getDriveAuthorization();

      if (authorization == null) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] Error: Could not get Drive authorization.',
        );
        return null;
      }

      final authHeaders = {
        'Authorization': 'Bearer ${authorization.accessToken}',
      };
      final authenticateClient = GoogleAuthClient(authHeaders);
      return drive.DriveApi(authenticateClient);
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error getting Drive API: $e',
      );
      return null;
    }
  }

  /// Uploads data to Google Drive App Data folder (hidden from user)
  /// This uses the 'appDataFolder' special folder that is:
  /// - Hidden from the user in Drive UI
  /// - Not visible in recent files or shortcuts
  /// - Only accessible by this app
  Future<void> uploadToDrive(Uint8List data, BackupInfo backupInfo) async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Starting upload to Google Drive appDataFolder...',
      );
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Backup version: ${backupInfo.version}',
      );
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Data size to upload: ${data.length} bytes',
      );
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] First 20 bytes: ${data.take(20).toList()}',
      );

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception('Failed to get Drive API - user may not be signed in');
      }

      // Upload backup file to appDataFolder
      await _uploadFile(driveApi, _backupFileName, data);

      // Upload metadata file to appDataFolder
      final metadataJson = jsonEncode(backupInfo.toJson());
      final metadataBytes = Uint8List.fromList(utf8.encode(metadataJson));
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Metadata JSON: $metadataJson',
      );
      await _uploadFile(driveApi, _metadataFileName, metadataBytes);

      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Upload completed successfully.',
      );
    } catch (e) {
      debugPrint('DEBUG: [GoogleDriveBackupService] Error during upload: $e');
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> _uploadFile(
    drive.DriveApi driveApi,
    String fileName,
    Uint8List data,
  ) async {
    // Search in appDataFolder space
    final query = "name = '$fileName'";
    final fileList = await driveApi.files.list(
      q: query,
      spaces: 'appDataFolder',
    );

    final media = drive.Media(Stream.value(data), data.length);

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Updating existing file: $fileName ($existingFileId)',
      );
      final updateFile = drive.File()..name = fileName;
      await driveApi.files.update(
        updateFile,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Creating new file in appDataFolder: $fileName',
      );
      // Create file in appDataFolder (hidden from user)
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Downloads data from Google Drive appDataFolder
  Future<Uint8List> downloadFromDrive() async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Starting download from Google Drive appDataFolder...',
      );
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception('Failed to get Drive API - user may not be signed in');
      }

      // Search in appDataFolder space
      final query = "name = '$_backupFileName'";
      debugPrint('DEBUG: [GoogleDriveBackupService] Search query: $query');
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
      );

      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Files found: ${fileList.files?.length ?? 0}',
      );
      if (fileList.files != null) {
        for (var file in fileList.files!) {
          debugPrint(
            'DEBUG: [GoogleDriveBackupService]   - File: ${file.name} (id: ${file.id})',
          );
        }
      }

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] No backup found in appDataFolder.',
        );
        throw Exception('No backup found. Please perform a backup first.');
      }

      final fileId = fileList.files!.first.id!;
      debugPrint('DEBUG: [GoogleDriveBackupService] Downloading file: $fileId');

      final response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataList = [];
      await for (final data in response.stream) {
        dataList.addAll(data);
      }

      final result = Uint8List.fromList(dataList);
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Download completed. Received ${result.length} bytes.',
      );
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] First 20 bytes: ${result.take(20).toList()}',
      );
      return result;
    } catch (e) {
      debugPrint('DEBUG: [GoogleDriveBackupService] Error during download: $e');
      throw Exception('Download failed: $e');
    }
  }

  /// Gets the cloud backup info (version and timestamp)
  Future<BackupInfo?> getCloudBackupInfo() async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Fetching cloud backup info from appDataFolder...',
      );
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // Search in appDataFolder space
      final query = "name = '$_metadataFileName'";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] No backup metadata found in appDataFolder.',
        );
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataList = [];
      await for (final data in response.stream) {
        dataList.addAll(data);
      }

      final jsonString = utf8.decode(dataList);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final info = BackupInfo.fromJson(json);

      debugPrint('DEBUG: [GoogleDriveBackupService] Cloud backup info: $info');
      return info;
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error fetching backup info: $e',
      );
      return null;
    }
  }

  /// Checks if a backup exists on Google Drive appDataFolder
  Future<bool> backupExists() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // Search in appDataFolder space
      final query = "name = '$_backupFileName'";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
      );

      final exists = fileList.files != null && fileList.files!.isNotEmpty;
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Backup exists in appDataFolder: $exists',
      );
      return exists;
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error checking backup existence: $e',
      );
      return false;
    }
  }

  /// Deletes all backup files from Google Drive appDataFolder.
  /// This includes the encrypted backup file and metadata file.
  Future<void> deleteCloudBackup() async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Deleting cloud backup from appDataFolder...',
      );
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception('Failed to get Drive API - user may not be signed in');
      }

      // Delete backup file from appDataFolder
      await _deleteFile(driveApi, _backupFileName);

      // Delete metadata file from appDataFolder
      await _deleteFile(driveApi, _metadataFileName);

      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Cloud backup deleted successfully.',
      );
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error deleting cloud backup: $e',
      );
      throw Exception('Failed to delete cloud backup: $e');
    }
  }

  Future<void> _deleteFile(drive.DriveApi driveApi, String fileName) async {
    // Search in appDataFolder space
    final query = "name = '$fileName'";
    final fileList = await driveApi.files.list(
      q: query,
      spaces: 'appDataFolder',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final fileId = fileList.files!.first.id!;
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Deleting file: $fileName ($fileId)',
      );
      await driveApi.files.delete(fileId);
    } else {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] File not found in appDataFolder: $fileName',
      );
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
