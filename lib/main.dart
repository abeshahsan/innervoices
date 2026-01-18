import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/applock/applock_bloc.dart';
import 'package:innervoices/bloc/note/note_bloc.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/data/repositories/auth_repository_impl.dart';
import 'package:innervoices/data/repositories/note_repository_realm.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/data/services/note_realm_service.dart';
import 'package:innervoices/data/services/realm_manager.dart';
import 'package:innervoices/ui/screens/lock_screen.dart';
import 'package:innervoices/ui/widgets/auth_gate.dart';
import 'package:innervoices/ui/widgets/blur_on_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Realm singleton
  RealmManager.instance.initialize();

  runApp(const InnerVoicesApp());
}

class InnerVoicesApp extends StatelessWidget {
  const InnerVoicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    /***** Initialize services using shared Realm instance *****/
    final googleAuthService = GoogleAuthService();
    final noteRealmService = NoteRealmService(RealmManager.instance.realm);
    /***** End services initialization *****/

    /***** Initialize repositories *****/
    final authRepository = AuthRepositoryImpl(googleAuthService);

    final noteRepository = NoteRepositoryRealm(
      noteRealmService: noteRealmService,
    );
    /***** End repositories initialization *****/

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(authRepository)..add(CheckAuthStatus()),
        ),
        BlocProvider<NoteBloc>(
          create: (context) => NoteBloc(noteRepository, '')..add(LoadNotes()),
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
