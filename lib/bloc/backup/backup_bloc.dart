import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/backup/backup_event.dart';
import 'package:innervoices/bloc/backup/backup_state.dart';
import 'package:innervoices/data/repositories/backup_repository.dart';
import 'package:innervoices/models/backup_info.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final BackupRepository backupRepository;

  BackupBloc(this.backupRepository) : super(BackupState.initial()) {
    on<CheckSyncStatus>(_onCheckSyncStatus);
    on<TriggerBackup>(_onTriggerBackup);
    on<TriggerRestore>(_onTriggerRestore);
    on<NotifyLocalChange>(_onNotifyLocalChange);
    on<DeleteCloudBackup>(_onDeleteCloudBackup);
  }

  Future<void> _onCheckSyncStatus(
    CheckSyncStatus event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('DEBUG: [BackupBloc] Checking sync status...');
    try {
      final syncStatus = await backupRepository.getSyncStatus();
      final localInfo = await backupRepository.getLocalBackupInfo();
      final cloudInfo = await backupRepository.getCloudBackupInfo();

      debugPrint('DEBUG: [BackupBloc] Sync status: $syncStatus');
      debugPrint(
        'DEBUG: [BackupBloc] Local: v${localInfo.version}, Cloud: v${cloudInfo?.version ?? 'none'}',
      );

      emit(
        state.copyWith(
          syncStatus: syncStatus,
          localInfo: localInfo,
          cloudInfo: cloudInfo,
          clearError: true,
        ),
      );
    } catch (e) {
      debugPrint('DEBUG: [BackupBloc] Error checking sync status: $e');
      emit(
        state.copyWith(
          syncStatus: SyncStatus.unknown,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTriggerBackup(
    TriggerBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('DEBUG: [BackupBloc] Triggering backup...');
    emit(state.copyWith(status: BackupStatus.loading, clearError: true));

    try {
      await backupRepository.backupToCloud();

      final localInfo = await backupRepository.getLocalBackupInfo();
      final cloudInfo = await backupRepository.getCloudBackupInfo();

      debugPrint(
        'DEBUG: [BackupBloc] Backup successful. Version: ${localInfo.version}',
      );

      emit(
        state.copyWith(
          status: BackupStatus.success,
          syncStatus: SyncStatus.inSync,
          localInfo: localInfo,
          cloudInfo: cloudInfo,
          lastSyncedAt: DateTime.now(),
        ),
      );
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupBloc] Backup failed: $e');
      debugPrint('DEBUG: [BackupBloc] Stack: $stack');
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTriggerRestore(
    TriggerRestore event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('DEBUG: [BackupBloc] Triggering restore...');
    emit(state.copyWith(status: BackupStatus.loading, clearError: true));

    try {
      await backupRepository.restoreFromCloud();

      final localInfo = await backupRepository.getLocalBackupInfo();
      final cloudInfo = await backupRepository.getCloudBackupInfo();

      debugPrint(
        'DEBUG: [BackupBloc] Restore successful. App restart required.',
      );

      // After successful restore, signal that app needs to restart
      // to reinitialize all services with the restored data
      emit(
        state.copyWith(
          status: BackupStatus.success,
          syncStatus: SyncStatus.inSync,
          localInfo: localInfo,
          cloudInfo: cloudInfo,
          lastSyncedAt: DateTime.now(),
          requiresRestart: true, // Signal that app should restart
        ),
      );
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupBloc] Restore failed: $e');
      debugPrint('DEBUG: [BackupBloc] Stack: $stack');
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onNotifyLocalChange(
    NotifyLocalChange event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('DEBUG: [BackupBloc] Local change detected...');
    try {
      await backupRepository.notifyLocalChange();

      final localInfo = await backupRepository.getLocalBackupInfo();
      final syncStatus = await backupRepository.getSyncStatus();

      debugPrint(
        'DEBUG: [BackupBloc] Local version incremented to: ${localInfo.version}',
      );

      emit(state.copyWith(localInfo: localInfo, syncStatus: syncStatus));
    } catch (e) {
      debugPrint('DEBUG: [BackupBloc] Error notifying local change: $e');
    }
  }

  Future<void> _onDeleteCloudBackup(
    DeleteCloudBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('DEBUG: [BackupBloc] Deleting cloud backup...');
    emit(state.copyWith(status: BackupStatus.loading, clearError: true));

    try {
      await backupRepository.deleteCloudBackup();

      final syncStatus = await backupRepository.getSyncStatus();

      debugPrint('DEBUG: [BackupBloc] Cloud backup deleted successfully.');

      emit(
        state.copyWith(
          status: BackupStatus.success,
          syncStatus: syncStatus,
          cloudInfo: null,
        ),
      );
    } catch (e, stack) {
      debugPrint('DEBUG: [BackupBloc] Delete failed: $e');
      debugPrint('DEBUG: [BackupBloc] Stack: $stack');
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
