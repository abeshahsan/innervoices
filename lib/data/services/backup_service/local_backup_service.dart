import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:innervoices/models/backup_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  final Realm realm;
  static const String _localVersionKey = 'local_backup_version';
  static const String _localTimestampKey = 'local_backup_timestamp';

  LocalBackupService(this.realm);

  /// Exports the current Realm data to bytes
  Future<Uint8List> exportLocalRealm() async {
    debugPrint('DEBUG: [LocalBackupService] Starting exportLocalRealm...');
    final tempDir = await getTemporaryDirectory();
    final backupFile = File('${tempDir.path}/inner_voices_backup.realm');

    if (await backupFile.exists()) {
      debugPrint(
        'DEBUG: [LocalBackupService] Deleting existing temp file at ${backupFile.path}',
      );
      await backupFile.delete();
    }

    try {
      debugPrint(
        'DEBUG: [LocalBackupService] Realm writeCopy starting to ${backupFile.path}',
      );
      realm.writeCopy(
        Configuration.local(
          realm.config.schemaObjects.toList(),
          path: backupFile.path,
        ),
      );
      debugPrint('DEBUG: [LocalBackupService] Realm writeCopy finished.');

      final bytes = await backupFile.readAsBytes();
      debugPrint(
        'DEBUG: [LocalBackupService] Read ${bytes.length} bytes from file.',
      );
      return bytes;
    } catch (e) {
      debugPrint('DEBUG: [LocalBackupService] Error during export: $e');
      rethrow;
    } finally {
      if (await backupFile.exists()) {
        debugPrint('DEBUG: [LocalBackupService] Cleaning up temp file.');
        await backupFile.delete();
      }
    }
  }

  /// Restores the Realm file from the provided bytes
  Future<void> restoreLocalRealm(Uint8List bytes) async {
    debugPrint(
      'DEBUG: [LocalBackupService] Starting restoreLocalRealm with ${bytes.length} bytes...',
    );
    final appDir = await getApplicationDocumentsDirectory();
    final realmFile = File('${appDir.path}/default.realm');

    // Close the current realm instance to allow file replacement
    debugPrint('DEBUG: [LocalBackupService] Closing Realm instance.');
    realm.close();

    debugPrint(
      'DEBUG: [LocalBackupService] Writing bytes to ${realmFile.path}',
    );
    await realmFile.writeAsBytes(bytes, flush: true);
    debugPrint('DEBUG: [LocalBackupService] Restore completed.');
  }

  /// Gets the local backup info (version and timestamp)
  Future<BackupInfo> getLocalBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_localVersionKey) ?? 0;
      final timestampStr = prefs.getString(_localTimestampKey);
      final timestamp = timestampStr != null
          ? DateTime.parse(timestampStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final info = BackupInfo(version: version, timestamp: timestamp);
      debugPrint('DEBUG: [LocalBackupService] Local backup info: $info');
      return info;
    } catch (e) {
      debugPrint(
        'DEBUG: [LocalBackupService] Error getting local backup info: $e',
      );
      return BackupInfo.initial();
    }
  }

  /// Saves the local backup info
  Future<void> saveLocalBackupInfo(BackupInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_localVersionKey, info.version);
      await prefs.setString(
        _localTimestampKey,
        info.timestamp.toIso8601String(),
      );
      debugPrint('DEBUG: [LocalBackupService] Saved local backup info: $info');
    } catch (e) {
      debugPrint(
        'DEBUG: [LocalBackupService] Error saving local backup info: $e',
      );
    }
  }

  /// Increments the local version (called when local data changes)
  Future<BackupInfo> incrementLocalVersion() async {
    final current = await getLocalBackupInfo();
    final updated = current.increment();
    await saveLocalBackupInfo(updated);
    debugPrint(
      'DEBUG: [LocalBackupService] Incremented local version to: ${updated.version}',
    );
    return updated;
  }
}
