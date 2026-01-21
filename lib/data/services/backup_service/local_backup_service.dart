import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:innervoices/models/backup_info.dart';
import 'package:innervoices/data/services/realm_manager.dart';
import 'package:innervoices/data/models/realm/note_realm_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  final Realm realm;
  static const String _localVersionKey = 'local_backup_version';
  static const String _localTimestampKey = 'local_backup_timestamp';

  LocalBackupService(this.realm);

  /// Debug helper: Count notes in a Realm instance
  int _countNotesInRealm(Realm r) {
    try {
      return r.all<NoteRealm>().length;
    } catch (e) {
      debugPrint('DEBUG: [LocalBackupService] Error counting notes: $e');
      return -1;
    }
  }

  /// Debug helper: List all notes in a Realm instance
  void _debugListNotes(Realm r, String context) {
    try {
      final notes = r.all<NoteRealm>();
      debugPrint(
        'DEBUG: [LocalBackupService] [$context] Total notes: ${notes.length}',
      );
      for (var note in notes) {
        debugPrint(
          'DEBUG: [LocalBackupService] [$context]   - Note: id=${note.id}, title="${note.title}", userId="${note.userId}"',
        );
      }
    } catch (e) {
      debugPrint(
        'DEBUG: [LocalBackupService] [$context] Error listing notes: $e',
      );
    }
  }

  /// Exports the current Realm data to bytes
  Future<Uint8List> exportLocalRealm() async {
    debugPrint('DEBUG: [LocalBackupService] Starting exportLocalRealm...');

    // Debug: Show notes before export
    _debugListNotes(realm, 'BEFORE EXPORT');

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

      // Verify the backup file by opening it temporarily
      final verifyConfig = Configuration.local(
        [NoteRealm.schema],
        path: backupFile.path,
        isReadOnly: true,
      );
      final verifyRealm = Realm(verifyConfig);
      _debugListNotes(verifyRealm, 'BACKUP FILE VERIFICATION');
      verifyRealm.close();

      final bytes = await backupFile.readAsBytes();
      debugPrint(
        'DEBUG: [LocalBackupService] Read ${bytes.length} bytes from backup file.',
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

  /// Restores the Realm file from the provided bytes.
  /// IMPORTANT: After calling this, the app should be restarted to reload
  /// all services with the new Realm instance.
  Future<void> restoreLocalRealm(Uint8List bytes) async {
    debugPrint(
      'DEBUG: [LocalBackupService] Starting restoreLocalRealm with ${bytes.length} bytes...',
    );

    // CRITICAL: Get the actual Realm path from the current configuration
    // Do NOT use getApplicationDocumentsDirectory() as it returns a different path
    final currentRealmPath = realm.config.path;
    final realmDir = File(currentRealmPath).parent.path;

    debugPrint(
      'DEBUG: [LocalBackupService] Current Realm path: $currentRealmPath',
    );
    debugPrint('DEBUG: [LocalBackupService] Realm directory: $realmDir');

    final realmFile = File(currentRealmPath);
    final realmLockFile = File('$currentRealmPath.lock');
    final realmManagementDir = Directory('$currentRealmPath.management');

    // Debug: Show current notes before restore
    debugPrint('DEBUG: [LocalBackupService] Notes BEFORE restore:');
    _debugListNotes(RealmManager.instance.realm, 'BEFORE RESTORE');

    // Close the current realm instance to allow file replacement
    debugPrint(
      'DEBUG: [LocalBackupService] Closing Realm instance via RealmManager.',
    );
    RealmManager.instance.close();

    // Small delay to ensure file handles are released
    await Future.delayed(const Duration(milliseconds: 200));

    // Delete existing Realm files
    try {
      if (await realmFile.exists()) {
        debugPrint(
          'DEBUG: [LocalBackupService] Deleting existing realm file: $currentRealmPath',
        );
        await realmFile.delete();
        debugPrint(
          'DEBUG: [LocalBackupService] Realm file deleted successfully.',
        );
      }
      if (await realmLockFile.exists()) {
        debugPrint(
          'DEBUG: [LocalBackupService] Deleting existing realm.lock file.',
        );
        await realmLockFile.delete();
      }
      if (await realmManagementDir.exists()) {
        debugPrint(
          'DEBUG: [LocalBackupService] Deleting existing realm.management directory.',
        );
        await realmManagementDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('DEBUG: [LocalBackupService] Error deleting old files: $e');
    }

    // Write the backup bytes to a temp file first, then verify
    final tempRestoreFile = File('$realmDir/restore_temp.realm');
    debugPrint(
      'DEBUG: [LocalBackupService] Writing ${bytes.length} bytes to temp file: ${tempRestoreFile.path}',
    );
    await tempRestoreFile.writeAsBytes(bytes, flush: true);

    // Verify the temp file contains valid data
    try {
      debugPrint(
        'DEBUG: [LocalBackupService] Verifying restored data in temp file...',
      );
      final verifyConfig = Configuration.local(
        [NoteRealm.schema],
        path: tempRestoreFile.path,
        isReadOnly: true,
      );
      final verifyRealm = Realm(verifyConfig);
      _debugListNotes(verifyRealm, 'RESTORED DATA VERIFICATION');
      final noteCount = _countNotesInRealm(verifyRealm);
      verifyRealm.close();
      debugPrint(
        'DEBUG: [LocalBackupService] Verified $noteCount notes in restored data.',
      );
    } catch (e) {
      debugPrint(
        'DEBUG: [LocalBackupService] ERROR: Restored file verification failed: $e',
      );
      // Clean up temp file
      if (await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
      }
      throw Exception('Restored backup file is invalid: $e');
    }

    // Move temp file to actual location
    debugPrint(
      'DEBUG: [LocalBackupService] Moving temp file to $currentRealmPath',
    );
    await tempRestoreFile.rename(currentRealmPath);

    // Reinitialize Realm with the restored data
    debugPrint(
      'DEBUG: [LocalBackupService] Reinitializing Realm after restore.',
    );
    RealmManager.instance.reinitialize();

    // Verify notes after reinitialize
    debugPrint(
      'DEBUG: [LocalBackupService] Notes AFTER restore and reinitialize:',
    );
    _debugListNotes(RealmManager.instance.realm, 'AFTER RESTORE');

    debugPrint('DEBUG: [LocalBackupService] Restore completed successfully.');
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
