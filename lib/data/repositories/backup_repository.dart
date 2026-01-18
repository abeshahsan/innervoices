import 'package:innervoices/models/backup_info.dart';

abstract class BackupRepository {
  /// Performs a full backup: Export -> Encrypt -> Upload
  Future<void> backupToCloud();

  /// Performs a full restore: Download -> Decrypt -> Restore
  Future<void> restoreFromCloud();

  /// Checks if a backup exists in the cloud
  Future<bool> hasCloudBackup();

  /// Gets the current sync status between local and cloud
  Future<SyncStatus> getSyncStatus();

  /// Gets local backup info
  Future<BackupInfo> getLocalBackupInfo();

  /// Gets cloud backup info
  Future<BackupInfo?> getCloudBackupInfo();

  /// Notifies that local data has changed
  Future<void> notifyLocalChange();
}
