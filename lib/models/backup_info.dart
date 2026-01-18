import 'package:equatable/equatable.dart';

/// Represents backup version information for sync status comparison
class BackupInfo extends Equatable {
  final int version;
  final DateTime timestamp;

  const BackupInfo({required this.version, required this.timestamp});

  factory BackupInfo.initial() =>
      BackupInfo(version: 0, timestamp: DateTime.fromMillisecondsSinceEpoch(0));

  BackupInfo increment() =>
      BackupInfo(version: version + 1, timestamp: DateTime.now());

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    version: json['version'] as int? ?? 0,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  List<Object?> get props => [version, timestamp];

  @override
  String toString() => 'BackupInfo(version: $version, timestamp: $timestamp)';
}

/// Represents the sync status between local and cloud backups
enum SyncStatus {
  /// Local and cloud are in sync
  inSync,

  /// Local has newer changes than cloud
  localAhead,

  /// Cloud has newer backup than local
  cloudAhead,

  /// No backup exists anywhere
  noBackup,

  /// Unable to determine status (e.g., offline)
  unknown,
}
