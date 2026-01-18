part of 'user_bloc.dart';

@immutable
sealed class UserState {}

// Initial state when app starts
final class UserInitial extends UserState {}

// Loading state while checking auth or signing in
final class UserLoading extends UserState {}

// User is authenticated
final class UserAuthenticated extends UserState {
  final UserModel user;
  final GoogleSignInAccount googleAccount;

  UserAuthenticated(this.user, this.googleAccount);
}

// User is not authenticated
final class UserUnauthenticated extends UserState {}

// Error state
final class UserError extends UserState {
  final String message;

  UserError(this.message);
}
