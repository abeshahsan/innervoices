import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/note/note_bloc.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/data/repositories/auth_repository_impl.dart';
import 'package:innervoices/data/repositories/note_repository_realm.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/data/services/note_realm_service.dart';
import 'package:innervoices/data/services/realm_manager.dart';
import 'package:innervoices/presentation/screens/home.dart';
import 'package:innervoices/presentation/screens/sign_in.dart';

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

    return BlocProvider<UserBloc>(
      create: (context) => UserBloc(authRepository)..add(CheckAuthStatus()),
      child: MaterialApp(
        title: 'Inner Voices',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: AuthGate(noteRepository: noteRepository),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final NoteRepositoryRealm noteRepository;

  const AuthGate({super.key, required this.noteRepository});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading || state is UserInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is UserAuthenticated) {
          // Create NoteBloc with authenticated user's ID
          return BlocProvider<NoteBloc>(
            create: (context) =>
                NoteBloc(noteRepository, state.firebaseUser.uid)
                  ..add(LoadNotes()),
            child: const HomePage(),
          );
        } else {
          return const SignInPage();
        }
      },
    );
  }
}
