import 'package:google_sign_in/google_sign_in.dart';
import 'package:innervoices/data/services/google_auth_service.dart';
import 'package:innervoices/models/user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthService _googleAuthService;

  AuthRepositoryImpl(this._googleAuthService);

  @override
  Future<void> initialize() {
    return _googleAuthService.initialize();
  }

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() {
    return _googleAuthService.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _googleAuthService.signOut();
  }

  @override
  GoogleSignInAccount? get currentUser => _googleAuthService.currentUser;

  @override
  UserModel? get currentUserModel => _googleAuthService.currentUserModel;

  @override
  Stream<GoogleSignInAccount?> authStateChanges() =>
      _googleAuthService.authStateChanges;
}
