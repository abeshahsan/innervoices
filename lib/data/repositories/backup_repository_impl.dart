import 'package:flutter/widgets.dart';
import 'package:innervoices/data/repositories/backup_repository.dart';
import 'package:innervoices/data/services/backup_service/backup_encryption_service.dart';
import 'package:innervoices/data/services/backup_service/google_drive_backup_service.dart';
import 'package:innervoices/data/services/backup_service/local_backup_service.dart';
import 'package:innervoices/models/backup_info.dart';

class BackupRepositoryImpl implements BackupRepository {
  final LocalBackupService localService;
  final GoogleDriveBackupService cloudService;
  final BackupEncryptionService encryptionService;

  BackupRepositoryImpl({
    required this.localService,
    required this.cloudService,
    required this.encryptionService,
  });

  @override
  Future<void> backupToCloud() async {
    try {
      debugPrint('DEBUG: [BackupRepo] ========== STARTING BACKUP ==========');

      // 1. Export local Realm
      debugPrint('DEBUG: [BackupRepo] Step 1: Exporting local Realm...');
      final bytes = await localService.exportLocalRealm();
      debugPrint(
        'DEBUG: [BackupRepo] Export successful. Raw Realm size: ${bytes.length} bytes.',
      );
      debugPrint(
        'DEBUG: [BackupRepo] Raw Realm first 20 bytes: ${bytes.take(20).toList()}',
      );

      // 2. Encrypt data
      debugPrint('DEBUG: [BackupRepo] Step 2: Encrypting data...');
      final encryptedBytes = await encryptionService.encrypt(bytes);
      debugPrint(
        'DEBUG: [BackupRepo] Encryption successful. Encrypted size: ${encryptedBytes.length} bytes.',
      );
      debugPrint(
        'DEBUG: [BackupRepo] Encrypted first 20 bytes: ${encryptedBytes.take(20).toList()}',
      );

      // 3. Get current local version and increment
      debugPrint('DEBUG: [BackupRepo] Step 3: Getting backup info...');
      final localInfo = await localService.getLocalBackupInfo();
      final newInfo = localInfo.increment();
      debugPrint('DEBUG: [BackupRepo] New backup version: ${newInfo.version}');

      // 4. Upload to cloud with version info
      debugPrint('DEBUG: [BackupRepo] Step 4: Uploading to cloud...');
      await cloudService.uploadToDrive(encryptedBytes, newInfo);

      // 5. Save new version info locally
      debugPrint('DEBUG: [BackupRepo] Step 5: Saving local backup info...');
      await localService.saveLocalBackupInfo(newInfo);

      debugPrint(
        'DEBUG: [BackupRepo] ========== BACKUP COMPLETED. Version: ${newInfo.version} ==========',
      );
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupRepo] ========== BACKUP FAILED ==========');
      debugPrint('DEBUG: [BackupRepo] Error: $e');
      debugPrint('DEBUG: [BackupRepo] Stack trace: $stack');
      throw Exception('Backup failed: $e');
    }
  }

  @override
  Future<void> restoreFromCloud() async {
    try {
      debugPrint('DEBUG: [BackupRepo] ========== STARTING RESTORE ==========');

      // 1. Download from cloud
      debugPrint('DEBUG: [BackupRepo] Step 1: Downloading from cloud...');
      final encryptedBytes = await cloudService.downloadFromDrive();
      debugPrint(
        'DEBUG: [BackupRepo] Download successful. Encrypted size: ${encryptedBytes.length} bytes.',
      );
      debugPrint(
        'DEBUG: [BackupRepo] Encrypted first 20 bytes: ${encryptedBytes.take(20).toList()}',
      );

      // 2. Decrypt data
      debugPrint('DEBUG: [BackupRepo] Step 2: Decrypting data...');
      final decryptedBytes = await encryptionService.decrypt(encryptedBytes);
      debugPrint(
        'DEBUG: [BackupRepo] Decryption successful. Decrypted (raw Realm) size: ${decryptedBytes.length} bytes.',
      );
      debugPrint(
        'DEBUG: [BackupRepo] Decrypted first 20 bytes: ${decryptedBytes.take(20).toList()}',
      );

      // 3. Restore to local Realm
      debugPrint('DEBUG: [BackupRepo] Step 3: Restoring to local Realm...');
      await localService.restoreLocalRealm(decryptedBytes);

      // 4. Get cloud version info and save locally
      debugPrint('DEBUG: [BackupRepo] Step 4: Syncing version info...');
      final cloudInfo = await cloudService.getCloudBackupInfo();
      debugPrint('DEBUG: [BackupRepo] Cloud backup info: $cloudInfo');
      if (cloudInfo != null) {
        await localService.saveLocalBackupInfo(cloudInfo);
        debugPrint('DEBUG: [BackupRepo] Saved cloud info to local.');
      }

      debugPrint('DEBUG: [BackupRepo] ========== RESTORE COMPLETED ==========');
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupRepo] ========== RESTORE FAILED ==========');
      debugPrint('DEBUG: [BackupRepo] Error: $e');
      debugPrint('DEBUG: [BackupRepo] Stack trace: $stack');
      throw Exception('Restore failed: $e');
    }
  }

  @override
  Future<bool> hasCloudBackup() async {
    try {
      return await cloudService.backupExists();
    } catch (e) {
      debugPrint('DEBUG: [BackupRepo] Error checking cloud backup: $e');
      return false;
    }
  }

  @override
  Future<SyncStatus> getSyncStatus() async {
    try {
      debugPrint('DEBUG: [BackupRepo] Checking sync status...');

      final localInfo = await localService.getLocalBackupInfo();
      final cloudInfo = await cloudService.getCloudBackupInfo();

      debugPrint(
        'DEBUG: [BackupRepo] Local version: ${localInfo.version}, Cloud version: ${cloudInfo?.version ?? 'null'}',
      );

      if (cloudInfo == null) {
        if (localInfo.version == 0) {
          debugPrint('DEBUG: [BackupRepo] Sync status: noBackup');
          return SyncStatus.noBackup;
        }
        debugPrint(
          'DEBUG: [BackupRepo] Sync status: localAhead (no cloud backup)',
        );
        return SyncStatus.localAhead;
      }

      if (localInfo.version == cloudInfo.version) {
        debugPrint('DEBUG: [BackupRepo] Sync status: inSync');
        return SyncStatus.inSync;
      } else if (localInfo.version > cloudInfo.version) {
        debugPrint('DEBUG: [BackupRepo] Sync status: localAhead');
        return SyncStatus.localAhead;
      } else {
        debugPrint('DEBUG: [BackupRepo] Sync status: cloudAhead');
        return SyncStatus.cloudAhead;
      }
    } catch (e) {
      debugPrint('DEBUG: [BackupRepo] Error getting sync status: $e');
      return SyncStatus.unknown;
    }
  }

  @override
  Future<BackupInfo> getLocalBackupInfo() async {
    return await localService.getLocalBackupInfo();
  }

  @override
  Future<BackupInfo?> getCloudBackupInfo() async {
    return await cloudService.getCloudBackupInfo();
  }

  @override
  Future<void> notifyLocalChange() async {
    debugPrint(
      'DEBUG: [BackupRepo] Local change detected, incrementing version...',
    );
    await localService.incrementLocalVersion();
  }

  @override
  Future<void> deleteCloudBackup() async {
    try {
      debugPrint('DEBUG: [BackupRepo] Deleting cloud backup...');
      await cloudService.deleteCloudBackup();
      debugPrint('DEBUG: [BackupRepo] Cloud backup deleted successfully.');
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupRepo] Failed to delete cloud backup: $e');
      debugPrint('DEBUG: [BackupRepo] Stack trace: $stack');
      throw Exception('Failed to delete cloud backup: $e');
    }
  }
}
