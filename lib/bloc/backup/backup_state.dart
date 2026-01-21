import 'package:equatable/equatable.dart';
import 'package:innervoices/models/backup_info.dart';

enum BackupStatus { initial, loading, success, failure }

class BackupState extends Equatable {
  final BackupStatus status;
  final SyncStatus syncStatus;
  final BackupInfo localInfo;
  final BackupInfo? cloudInfo;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final bool requiresRestart; // Set to true after successful restore

  const BackupState({
    this.status = BackupStatus.initial,
    this.syncStatus = SyncStatus.unknown,
    required this.localInfo,
    this.cloudInfo,
    this.lastSyncedAt,
    this.errorMessage,
    this.requiresRestart = false,
  });

  // Helper for initial state with proper default
  factory BackupState.initial() => BackupState(localInfo: BackupInfo.initial());

  BackupState copyWith({
    BackupStatus? status,
    SyncStatus? syncStatus,
    BackupInfo? localInfo,
    BackupInfo? cloudInfo,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
    bool? requiresRestart,
  }) {
    return BackupState(
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      localInfo: localInfo ?? this.localInfo,
      cloudInfo: cloudInfo ?? this.cloudInfo,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requiresRestart: requiresRestart ?? this.requiresRestart,
    );
  }

  /// Helper to determine the appropriate icon based on sync status
  String get syncStatusLabel {
    switch (syncStatus) {
      case SyncStatus.inSync:
        return 'Up to date';
      case SyncStatus.localAhead:
        return 'Local changes pending';
      case SyncStatus.cloudAhead:
        return 'Cloud backup available';
      case SyncStatus.noBackup:
        return 'No backup yet';
      case SyncStatus.unknown:
        return 'Checking...';
    }
  }

  @override
  List<Object?> get props => [
    status,
    syncStatus,
    localInfo,
    cloudInfo,
    lastSyncedAt,
    errorMessage,
    requiresRestart,
  ];
}
