import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:innervoices/models/user.dart';
import 'package:innervoices/data/repositories/auth_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository _authRepository;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;

  UserBloc(this._authRepository) : super(UserInitial()) {
    // Check auth status on app start
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // Handle sign in
    on<SignInRequested>(_onSignInRequested);

    // Handle sign out
    on<SignOutRequested>(_onSignOutRequested);

    // Handle user updates
    on<UserUpdated>(_onUserUpdated);

    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges().listen((account) {
      add(UserUpdated(account));
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      await _authRepository.initialize();
      final currentUser = _authRepository.currentUser;

      if (currentUser != null) {
        final user = _mapGoogleAccountToUser(currentUser);
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
      final account = await _authRepository.signInWithGoogle();

      if (account != null) {
        final user = _mapGoogleAccountToUser(account);
        emit(UserAuthenticated(user, account));
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
      await _authRepository.signOut();
      emit(UserUnauthenticated());
    } catch (e) {
      emit(UserError('Sign out failed: $e'));
    }
  }

  void _onUserUpdated(UserUpdated event, Emitter<UserState> emit) {
    if (event.googleAccount != null) {
      final user = _mapGoogleAccountToUser(event.googleAccount!);
      emit(UserAuthenticated(user, event.googleAccount!));
    } else {
      emit(UserUnauthenticated());
    }
  }

  UserModel _mapGoogleAccountToUser(GoogleSignInAccount account) {
    return UserModel(
      username: account.displayName ?? 'User',
      fullName: account.displayName ?? 'Unknown User',
      email: account.email,
      profilePictureUrl: account.photoUrl ?? '',
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
