import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:innervoices/models/user.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  static GoogleAuthService get instance => _instance;
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignIn get googleSignIn => _googleSignIn;
  bool _isInitialized = false;
  Completer<GoogleSignInAccount?>? _signInCompleter;

  GoogleSignInAccount? _currentUser;
  final _authStateController =
      StreamController<GoogleSignInAccount?>.broadcast();

  /// Initialize Google Sign In
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('DEBUG: [GoogleAuthService] Initializing Google Sign In...');
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
              _handleGoogleSignOut();
          }
        },
        onError: (error) {
          debugPrint('DEBUG: [GoogleAuthService] Auth event error: $error');
          if (_signInCompleter?.isCompleted == false) {
            _signInCompleter?.completeError('Authentication error: $error');
          }
        },
      );

      _isInitialized = true;
      debugPrint('DEBUG: [GoogleAuthService] Initialization complete.');
    } catch (e) {
      debugPrint('DEBUG: [GoogleAuthService] Initialization failed: $e');
      throw Exception('Failed to initialize Google Sign In: $e');
    }
  }

  Future<void> _handleGoogleSignIn(GoogleSignInAccount user) async {
    try {
      debugPrint(
        'DEBUG: [GoogleAuthService] Handling sign in for: ${user.email}',
      );

      // Just accept the sign-in, we'll request Drive scopes lazily when needed
      _currentUser = user;
      _authStateController.add(user);

      if (_signInCompleter?.isCompleted == false) {
        _signInCompleter?.complete(user);
      }
      debugPrint('DEBUG: [GoogleAuthService] Sign in successful.');
    } catch (e) {
      debugPrint('DEBUG: [GoogleAuthService] Sign in handling failed: $e');
      if (_signInCompleter?.isCompleted == false) {
        _signInCompleter?.completeError(e);
      }
    }
  }

  void _handleGoogleSignOut() {
    debugPrint('DEBUG: [GoogleAuthService] User signed out.');
    _currentUser = null;
    _authStateController.add(null);
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      debugPrint('DEBUG: [GoogleAuthService] Starting sign in flow...');
      if (!_isInitialized) {
        await initialize();
      }

      // Create a new completer for this sign-in attempt
      _signInCompleter = Completer<GoogleSignInAccount?>();

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
      debugPrint('DEBUG: [GoogleAuthService] Sign in failed: $e');
      throw Exception('Google Sign In failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      debugPrint('DEBUG: [GoogleAuthService] Signing out...');
      await _googleSignIn.signOut();
      _currentUser = null;
      _authStateController.add(null);
      debugPrint('DEBUG: [GoogleAuthService] Sign out complete.');
    } catch (e) {
      debugPrint('DEBUG: [GoogleAuthService] Sign out failed: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Auth state stream
  Stream<GoogleSignInAccount?> get authStateChanges =>
      _authStateController.stream;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Convert GoogleSignInAccount to UserModel
  UserModel? get currentUserModel {
    final account = currentUser;
    if (account == null) return null;

    return UserModel(
      fullName: account.displayName ?? 'User',
      email: account.email,
      username: account.displayName ?? 'User',
      profilePictureUrl: account.photoUrl ?? '',
    );
  }

  /// Get authorization for Drive API access
  /// This will prompt the user if scopes haven't been granted yet
  Future<GoogleSignInClientAuthorization?> getDriveAuthorization() async {
    final account = currentUser;
    if (account == null) {
      debugPrint(
        'DEBUG: [GoogleAuthService] No user signed in for Drive authorization',
      );
      return null;
    }

    try {
      debugPrint(
        'DEBUG: [GoogleAuthService] Requesting Drive authorization...',
      );

      // First try to get existing authorization
      var authorization = await account.authorizationClient
          .authorizationForScopes([
            'https://www.googleapis.com/auth/drive.file',
          ]);

      // If no existing authorization, request it (this prompts the user)
      if (authorization == null) {
        debugPrint(
          'DEBUG: [GoogleAuthService] No existing authorization, requesting...',
        );
        authorization = await account.authorizationClient.authorizeScopes([
          'https://www.googleapis.com/auth/drive.file',
        ]);
      }

      debugPrint('DEBUG: [GoogleAuthService] Drive authorization obtained.');
      return authorization;
    } catch (e) {
      debugPrint('DEBUG: [GoogleAuthService] Drive authorization failed: $e');
      return null;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
