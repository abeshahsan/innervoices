import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/backup/backup_bloc.dart';
import 'package:innervoices/bloc/backup/backup_event.dart';
import 'package:innervoices/bloc/backup/backup_state.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/models/backup_info.dart';
import 'package:innervoices/models/user.dart';
import 'package:innervoices/ui/screens/settings.dart';
import 'package:intl/intl.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserAuthenticated) {
                      final UserModel user = state.user;
                      return _buildUserHeader(user);
                    }
                    return _buildEmptyHeader();
                  },
                ),
                _buildAnimatedDetails(),
                _buildMainDrawerItems(),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Lock'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              AppLock.of(context)?.showLockScreen();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserHeader(UserModel user) {
    return UserAccountsDrawerHeader(
      accountName: Text(user.username),
      accountEmail: Text(user.email),
      currentAccountPicture: _buildProfilePicture(user.profilePictureUrl),
      decoration: const BoxDecoration(color: Colors.deepPurple),
      onDetailsPressed: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
    );
  }

  Widget _buildEmptyHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(color: Colors.deepPurple),
      child: Text(
        'Welcome!',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildAnimatedDetails() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showDetails
          ? Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: const Text('Switch Account'),
                  onTap: () {
                    // Navigate to switch account or perform action
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    context.read<UserBloc>().add(SignOutRequested());
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMainDrawerItems() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Account'),
          onTap: () {
            // Navigate to account page or perform action
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Settings()),
            );
          },
        ),
        const Divider(),
        _buildBackupTile(),
      ],
    );
  }

  Widget _buildBackupTile() {
    return BlocConsumer<BackupBloc, BackupState>(
      listener: (context, state) {
        if (state.status == BackupStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup successful!'),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state.status == BackupStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup failed: ${state.errorMessage}'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      },
      builder: (context, state) {
        final syncIcon = _getSyncIcon(state.syncStatus);
        final syncColor = _getSyncColor(state.syncStatus);
        final syncLabel = state.syncStatusLabel;

        final lastSynced = state.lastSyncedAt != null
            ? DateFormat('MMM d, HH:mm').format(state.lastSyncedAt!)
            : 'Never';

        return ListTile(
          leading: Icon(syncIcon, color: syncColor),
          title: const Text('Sync Backup'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(syncLabel, style: TextStyle(color: syncColor, fontSize: 12)),
              Text('Last synced: $lastSynced', style: TextStyle(fontSize: 11)),
            ],
          ),
          isThreeLine: true,
          trailing: state.status == BackupStatus.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _getSyncActionWidget(state),
          onTap: state.status == BackupStatus.loading
              ? null
              : () => _handleSyncTap(context, state),
          onLongPress: state.status == BackupStatus.loading
              ? null
              : () => _showBackupOptionsDialog(context, state),
        );
      },
    );
  }

  IconData _getSyncIcon(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.inSync:
        return Icons.cloud_done;
      case SyncStatus.localAhead:
        return Icons.cloud_upload;
      case SyncStatus.cloudAhead:
        return Icons.cloud_download;
      case SyncStatus.noBackup:
        return Icons.cloud_off;
      case SyncStatus.unknown:
        return Icons.cloud_queue;
    }
  }

  Color _getSyncColor(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.inSync:
        return Colors.green;
      case SyncStatus.localAhead:
        return Colors.orange;
      case SyncStatus.cloudAhead:
        return Colors.blue;
      case SyncStatus.noBackup:
        return Colors.grey;
      case SyncStatus.unknown:
        return Colors.grey;
    }
  }

  Widget? _getSyncActionWidget(BackupState state) {
    switch (state.syncStatus) {
      case SyncStatus.localAhead:
        return const Icon(Icons.arrow_upward, color: Colors.orange);
      case SyncStatus.cloudAhead:
        return const Icon(Icons.arrow_downward, color: Colors.blue);
      case SyncStatus.inSync:
        return const Icon(Icons.check, color: Colors.green);
      case SyncStatus.noBackup:
        return const Icon(Icons.add, color: Colors.grey);
      default:
        return const Icon(Icons.sync, color: Colors.grey);
    }
  }

  void _handleSyncTap(BuildContext context, BackupState state) {
    switch (state.syncStatus) {
      case SyncStatus.localAhead:
      case SyncStatus.noBackup:
        // Push local to cloud
        context.read<BackupBloc>().add(TriggerBackup());
        break;
      case SyncStatus.cloudAhead:
        // Show confirmation before restoring
        _showRestoreDialog(context);
        break;
      case SyncStatus.inSync:
        // Already synced, maybe refresh status
        context.read<BackupBloc>().add(CheckSyncStatus());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already in sync!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case SyncStatus.unknown:
        // Check status first
        context.read<BackupBloc>().add(CheckSyncStatus());
        break;
    }
  }

  void _showBackupOptionsDialog(BuildContext context, BackupState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local version: ${state.localInfo.version}'),
            Text('Cloud version: ${state.cloudInfo?.version ?? 'None'}'),
            const SizedBox(height: 16),
            const Text('Choose an action:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(CheckSyncStatus());
            },
            child: const Text('Refresh Status'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(TriggerBackup());
            },
            child: const Text('Force Upload'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showRestoreDialog(context);
            },
            child: const Text(
              'Restore from Cloud',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will overwrite your current local data with the cloud backup. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(TriggerRestore());
            },
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(String url) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      foregroundImage: NetworkImage(url),
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }
}
