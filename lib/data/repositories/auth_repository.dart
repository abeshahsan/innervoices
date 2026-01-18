import 'package:google_sign_in/google_sign_in.dart';
import 'package:innervoices/models/user.dart';

abstract class AuthRepository {
  Future<GoogleSignInAccount?> signInWithGoogle();
  Future<void> signOut();
  Future<void> initialize();
  GoogleSignInAccount? get currentUser;
  UserModel? get currentUserModel;
  Stream<GoogleSignInAccount?> authStateChanges();
}
