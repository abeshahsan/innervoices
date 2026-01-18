import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:innervoices/models/backup_info.dart';
import 'package:innervoices/data/services/google_auth_service.dart';

class GoogleDriveBackupService {
  final GoogleSignIn googleSignIn;
  static const String _backupFileName = 'inner_voices_backup.enc';
  static const String _metadataFileName = 'inner_voices_backup_meta.json';
  static const String _appFolderName = 'InnerVoicesBackup';

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

  /// Gets or creates the app folder for backups
  Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      // Search for existing folder
      final query =
          "name = '$_appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] Found existing app folder: ${fileList.files!.first.id}',
        );
        return fileList.files!.first.id;
      }

      // Create new folder
      final folder = drive.File()
        ..name = _appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final created = await driveApi.files.create(folder);
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Created new app folder: ${created.id}',
      );
      return created.id;
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error getting/creating app folder: $e',
      );
      return null;
    }
  }

  /// Uploads data to Google Drive with version info
  Future<void> uploadToDrive(Uint8List data, BackupInfo backupInfo) async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Starting upload to Google Drive...',
      );
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Backup version: ${backupInfo.version}',
      );

      final driveApi = await _getDriveApi();
      if (driveApi == null)
        throw Exception('Failed to get Drive API - user may not be signed in');

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) throw Exception('Failed to get/create app folder');

      // Upload backup file
      await _uploadFile(driveApi, folderId, _backupFileName, data);

      // Upload metadata file
      final metadataJson = jsonEncode(backupInfo.toJson());
      final metadataBytes = Uint8List.fromList(utf8.encode(metadataJson));
      await _uploadFile(driveApi, folderId, _metadataFileName, metadataBytes);

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
    String folderId,
    String fileName,
    Uint8List data,
  ) async {
    final query =
        "name = '$fileName' and '$folderId' in parents and trashed = false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId];

    final media = drive.Media(Stream.value(data), data.length);

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Updating existing file: $fileName ($existingFileId)',
      );
      // Don't set parents on update
      final updateFile = drive.File()..name = fileName;
      await driveApi.files.update(
        updateFile,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Creating new file: $fileName',
      );
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Downloads data from Google Drive
  Future<Uint8List> downloadFromDrive() async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Starting download from Google Drive...',
      );
      final driveApi = await _getDriveApi();
      if (driveApi == null)
        throw Exception('Failed to get Drive API - user may not be signed in');

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) throw Exception('Failed to get app folder');

      final query =
          "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] No backup found on Google Drive.',
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

      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Download completed. Received ${dataList.length} bytes.',
      );
      return Uint8List.fromList(dataList);
    } catch (e) {
      debugPrint('DEBUG: [GoogleDriveBackupService] Error during download: $e');
      throw Exception('Download failed: $e');
    }
  }

  /// Gets the cloud backup info (version and timestamp)
  Future<BackupInfo?> getCloudBackupInfo() async {
    try {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Fetching cloud backup info...',
      );
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return null;

      final query =
          "name = '$_metadataFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint(
          'DEBUG: [GoogleDriveBackupService] No backup metadata found.',
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

  /// Checks if a backup exists on Google Drive
  Future<bool> backupExists() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return false;

      final query =
          "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      final exists = fileList.files != null && fileList.files!.isNotEmpty;
      debugPrint('DEBUG: [GoogleDriveBackupService] Backup exists: $exists');
      return exists;
    } catch (e) {
      debugPrint(
        'DEBUG: [GoogleDriveBackupService] Error checking backup existence: $e',
      );
      return false;
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
