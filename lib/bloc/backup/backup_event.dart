import 'package:equatable/equatable.dart';

abstract class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => [];
}

/// Check the current sync status between local and cloud
class CheckSyncStatus extends BackupEvent {
  const CheckSyncStatus();
}

/// Trigger a backup to cloud
class TriggerBackup extends BackupEvent {
  const TriggerBackup();
}

/// Trigger a restore from cloud
class TriggerRestore extends BackupEvent {
  const TriggerRestore();
}

/// Notify that local data has changed (called when notes are added/updated/deleted)
class NotifyLocalChange extends BackupEvent {
  const NotifyLocalChange();
}

/// Delete all cloud backup files
class DeleteCloudBackup extends BackupEvent {
  const DeleteCloudBackup();
}
