import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:innervoices/models/user.dart';
import 'package:innervoices/services/google_auth.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GoogleAuthService _authService = GoogleAuthService();
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  UserBloc() : super(UserInitial()) {
    // Check auth status on app start
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // Handle sign in
    on<SignInRequested>(_onSignInRequested);

    // Handle sign out
    on<SignOutRequested>(_onSignOutRequested);

    // Handle user updates
    on<UserUpdated>(_onUserUpdated);

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((firebaseUser) {
      add(UserUpdated(firebaseUser));
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      await _authService.initialize();
      final currentUser = _authService.currentUser;

      if (currentUser != null) {
        final user = _mapFirebaseUserToUser(currentUser);
        emit(UserAuthenticated(user, currentUser));
      } else {
        emit(UserUnauthenticated());
      }
    } catch (e) {
      emit(UserError('Failed to check authentication status: $e'));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential?.user != null) {
        final user = _mapFirebaseUserToUser(userCredential!.user!);
        emit(UserAuthenticated(user, userCredential.user!));
      } else {
        emit(UserUnauthenticated());
      }
    } catch (e) {
      emit(UserError('Sign in failed: $e'));
      emit(UserUnauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      await _authService.signOut();
      emit(UserUnauthenticated());
    } catch (e) {
      emit(UserError('Sign out failed: $e'));
    }
  }

  void _onUserUpdated(UserUpdated event, Emitter<UserState> emit) {
    if (event.firebaseUser != null) {
      final user = _mapFirebaseUserToUser(event.firebaseUser!);
      emit(UserAuthenticated(user, event.firebaseUser!));
    } else {
      emit(UserUnauthenticated());
    }
  }

  UserModel _mapFirebaseUserToUser(firebase_auth.User firebaseUser) {
    return UserModel(
      username: firebaseUser.displayName ?? 'User',
      fullName: firebaseUser.displayName ?? 'Unknown User',
      email: firebaseUser.email ?? '',
      profilePictureUrl: firebaseUser.photoURL ?? '',
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
