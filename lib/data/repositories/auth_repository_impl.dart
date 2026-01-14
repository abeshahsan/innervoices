import 'package:firebase_auth/firebase_auth.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthService _googleAuthService;

  AuthRepositoryImpl(this._googleAuthService);

  @override
  Future<void> initialize() {
    return _googleAuthService.initialize();
  }

  @override
  Future<UserCredential?> signInWithGoogle() {
    return _googleAuthService.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _googleAuthService.signOut();
  }

  @override
  User? get currentUser => _googleAuthService.currentUser;

  @override
  Stream<User?> authStateChanges() => _googleAuthService.authStateChanges;
}
