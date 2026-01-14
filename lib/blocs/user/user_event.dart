part of 'user_bloc.dart';

@immutable
sealed class UserEvent {}

// Check if user is already signed in on app start
class CheckAuthStatus extends UserEvent {}

// Sign in event
class SignInRequested extends UserEvent {}

// Sign out event
class SignOutRequested extends UserEvent {}

// Update user info
class UserUpdated extends UserEvent {
  final firebase_auth.User? firebaseUser;

  UserUpdated(this.firebaseUser);
}
