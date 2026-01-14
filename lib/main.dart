import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/note/note_bloc.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/data/repositories/auth_repository_impl.dart';
import 'package:innervoices/data/repositories/note_repository.dart';
import 'package:innervoices/data/repositories/note_repository_impl.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/data/services/note_firestore_service.dart';
import 'package:innervoices/presentation/screens/home.dart';
import 'package:innervoices/presentation/screens/sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const InnerVoicesApp());
}

class InnerVoicesApp extends StatelessWidget {
  const InnerVoicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    /***** Initialize services *****/

    final googleAuthService = GoogleAuthService();
    final NoteFirestoreService noteFirestoreService = NoteFirestoreService();
    /***** End services initialization *****/

    /***** Initialize repositories *****/
    final authRepository = AuthRepositoryImpl(googleAuthService);

    final NoteRepository noteRepository = NoteRepositoryImpl(
      firestoreService: noteFirestoreService,
    );
    /***** End repositories initialization *****/

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(authRepository)..add(CheckAuthStatus()),
        ),
        BlocProvider<NoteBloc>(create: (context) => NoteBloc(noteRepository)..add(LoadNotes())),
      ],
      child: MaterialApp(
        title: 'Inner Voices',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading || state is UserInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is UserAuthenticated) {
          return const HomePage();
        } else {
          return const SignInPage();
        }
      },
    );
  }
}
