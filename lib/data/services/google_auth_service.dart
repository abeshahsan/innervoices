import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  Completer<UserCredential?>? _signInCompleter;

  // Initialize Google Sign In
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.initialize(
        serverClientId:
            '84968040559-d0q7u8dskkdgp8is0oilk5cajdn2oilc.apps.googleusercontent.com',
      );

      // Set up authentication event listener
      _googleSignIn.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          switch (event) {
            case GoogleSignInAuthenticationEventSignIn():
              _handleGoogleSignIn(event.user);
            case GoogleSignInAuthenticationEventSignOut():
              break;
          }
        },
        onError: (error) {
          if (_signInCompleter?.isCompleted == false) {
            _signInCompleter?.completeError('Authentication error: $error');
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Google Sign In: $e');
    }
  }

  Future<void> _handleGoogleSignIn(GoogleSignInAccount user) async {
    try {
      // Based on the working code from the original, use the authorization approach
      final GoogleSignInClientAuthorization? authorization = await user
          .authorizationClient
          .authorizationForScopes(['email']);

      if (authorization == null) {
        if (_signInCompleter?.isCompleted == false) {
          _signInCompleter?.completeError('Could not get authorization');
        }
        return;
      }

      // Create Firebase credential using the authorization token
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: user.authentication.idToken,
      );

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (_signInCompleter?.isCompleted == false) {
        _signInCompleter?.complete(userCredential);
      }
    } catch (e) {
      if (_signInCompleter?.isCompleted == false) {
        _signInCompleter?.completeError(e);
      }
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Create a new completer for this sign-in attempt
      _signInCompleter = Completer<UserCredential?>();

      // Start the authentication flow
      await _googleSignIn.authenticate();

      // Wait for the authentication event to complete with a timeout
      return await _signInCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign in timed out');
        },
      );
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Sign out from both Google and Firebase
  Future<void> signOut() async {
    try {
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;
}
