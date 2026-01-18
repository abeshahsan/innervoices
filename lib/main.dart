import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/applock/applock_bloc.dart';
import 'package:innervoices/bloc/backup/backup_bloc.dart';
import 'package:innervoices/bloc/backup/backup_event.dart';
import 'package:innervoices/bloc/note/note_bloc.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/data/repositories/auth_repository_impl.dart';
import 'package:innervoices/data/repositories/backup_repository_impl.dart';
import 'package:innervoices/data/repositories/note_repository_realm.dart';
import 'package:innervoices/data/services/backup_service/backup_encryption_service.dart';
import 'package:innervoices/data/services/backup_service/google_drive_backup_service.dart';
import 'package:innervoices/data/services/backup_service/local_backup_service.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/data/services/note_realm_service.dart';
import 'package:innervoices/data/services/realm_manager.dart';
import 'package:innervoices/ui/screens/lock_screen.dart';
import 'package:innervoices/ui/widgets/auth_gate.dart';
import 'package:innervoices/ui/widgets/blur_on_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Auth Service
  await GoogleAuthService.instance.initialize();

  // Initialize Realm singleton
  RealmManager.instance.initialize();

  runApp(const InnerVoicesApp());
}

class InnerVoicesApp extends StatelessWidget {
  const InnerVoicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    /***** Initialize services using shared Realm instance *****/
    final googleAuthService = GoogleAuthService.instance;
    final noteRealmService = NoteRealmService(RealmManager.instance.realm);

    final localBackupService = LocalBackupService(RealmManager.instance.realm);
    final googleDriveBackupService = GoogleDriveBackupService(
      googleSignIn: googleAuthService.googleSignIn,
    );
    final encryptionService = BackupEncryptionService();
    /***** End services initialization *****/

    /***** Initialize repositories *****/
    final authRepository = AuthRepositoryImpl(googleAuthService);

    final noteRepository = NoteRepositoryRealm(
      noteRealmService: noteRealmService,
    );

    final backupRepository = BackupRepositoryImpl(
      localService: localBackupService,
      cloudService: googleDriveBackupService,
      encryptionService: encryptionService,
    );
    /***** End repositories initialization *****/

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(authRepository)..add(CheckAuthStatus()),
        ),
        BlocProvider<BackupBloc>(
          create: (context) =>
              BackupBloc(backupRepository)..add(CheckSyncStatus()),
        ),
        BlocProvider<NoteBloc>(
          create: (context) =>
              NoteBloc(noteRepository, '', context.read<BackupBloc>())
                ..add(LoadNotes()),
        ),
        BlocProvider<ApplockBloc>(create: (context) => ApplockBloc()),
      ],
      child: MaterialApp(
        title: 'Inner Voices',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: AuthGate(),
        builder: (context, child) => BlurOnBackground(
          child: AppLock(
            builder: (context, arg) => child!,
            lockScreenBuilder: (context) {
              return BlocConsumer<ApplockBloc, ApplockState>(
                listener: (context, state) {
                  if (state is ApplockUnlocked) {
                    AppLock.of(context)?.didUnlock();
                  }
                },
                builder: (context, state) {
                  return const LockScreen();
                },
              );
            },
            initiallyEnabled: true,
            initialBackgroundLockLatency: Duration(seconds: 20),
          ),
        ),
      ),
    );
  }
}
