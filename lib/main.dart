import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const InnerVoiceApp());
}

class InnerVoiceApp extends StatelessWidget {
  const InnerVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inner Voices',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  final List<String> _logs = [];
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _initializeGoogleSignIn();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _log(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] ${isError ? '❌' : '✅'} $message';
    debugPrint(logMessage);
    if (mounted) {
      setState(() {
        _logs.insert(0, logMessage);
        if (_logs.length > 50) _logs.removeLast();
      });
    }
  }

  void _setupAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (mounted) {
          setState(() => _currentUser = user);
          if (user != null) {
            _log('Auth state: Signed in as ${user.email}');
            _log('UID: ${user.uid}');
            _log(
              'Provider: ${user.providerData.map((p) => p.providerId).join(", ")}',
            );
          } else {
            _log('Auth state: Signed out');
          }
        }
      },
      onError: (error) {
        _log('Auth state error: $error', isError: true);
      },
    );
  }

  Future<void> _initializeGoogleSignIn() async {
    _log('Initializing Google Sign-In...');
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(
        serverClientId:
            '84968040559-d0q7u8dskkdgp8is0oilk5cajdn2oilc.apps.googleusercontent.com',
      );

      signIn.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (!mounted) return;
          switch (event) {
            case GoogleSignInAuthenticationEventSignIn():
              _log('Google Sign-In event: User authenticated');
              _handleFirebaseSignIn(event.user);
            case GoogleSignInAuthenticationEventSignOut():
              _log('Google Sign-In event: User signed out');
          }
        },
        onError: (Object error) {
          _handleGoogleSignInError(error);
        },
      );

      setState(() => _isInitialized = true);
      _log('Google Sign-In initialized successfully');
    } catch (e) {
      _log('Failed to initialize: $e', isError: true);
      setState(() => _errorMessage = 'Failed to initialize: $e');
    }
  }

  void _handleGoogleSignInError(Object error) {
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          _log('Sign-in cancelled by user', isError: true);
        case GoogleSignInExceptionCode.interrupted:
          _log('Sign-in interrupted', isError: true);
        case GoogleSignInExceptionCode.clientConfigurationError:
          _log(
            'Client configuration error: ${error.description}',
            isError: true,
          );
        default:
          _log('Unhandled sign-in error: $error', isError: true);
      }
    } else {
      _log('Auth event error: $error', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleFirebaseSignIn(GoogleSignInAccount user) async {
    setState(() => _isLoading = true);
    _log('Starting Firebase authentication...');

    try {
      final GoogleSignInClientAuthorization? authorization = await user
          .authorizationClient
          .authorizationForScopes(['email']);

      if (authorization == null) {
        _log('Could not get authorization token', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      _log(
        'Got access token: ${authorization.accessToken.substring(0, 20)}...',
      );
      _log('Got ID token: ${user.authentication.idToken?.substring(0, 20)}...');

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: user.authentication.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;

      _log('Firebase sign-in successful!');
      _log('Display name: ${firebaseUser?.displayName}');
      _log('Email: ${firebaseUser?.email}');
      _log('Email verified: ${firebaseUser?.emailVerified}');
      _log('Photo URL: ${firebaseUser?.photoURL}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${firebaseUser?.displayName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _log('Firebase Auth error: ${e.code} - ${e.message}', isError: true);
      _showErrorSnackbar('Firebase error: ${e.message}');
    } catch (e) {
      _log('Unexpected error: $e', isError: true);
      _showErrorSnackbar('Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _log('User initiated sign-in');

    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      _handleGoogleSignInError(e);
    } catch (e) {
      _log('Sign-in error: $e', isError: true);
      _showErrorSnackbar('Sign-in failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    _log('User initiated sign-out');

    try {
      // Sign out from Firebase first
      await FirebaseAuth.instance.signOut();
      _log('Firebase sign-out successful');

      // Try to disconnect from Google (revoke access)
      // This may fail if token is already expired/revoked, which is okay
      try {
        await GoogleSignIn.instance.disconnect();
        _log('Google disconnect successful');
      } catch (googleError) {
        // Just log the error but don't fail - Firebase sign out already worked
        _log('Google disconnect warning: $googleError (non-critical)');
      }

      _log('Sign-out completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _log('Sign-out error: $e', isError: true);
      _showErrorSnackbar('Sign-out failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshToken() async {
    if (_currentUser == null) return;

    _log('Refreshing ID token...');
    try {
      final idToken = await _currentUser!.getIdToken(true);
      _log('Token refreshed: ${idToken?.substring(0, 20)}...');
      _showSuccessSnackbar('Token refreshed successfully');
    } catch (e) {
      _log('Token refresh failed: $e', isError: true);
      _showErrorSnackbar('Token refresh failed: $e');
    }
  }

  Future<void> _checkUserInfo() async {
    if (_currentUser == null) return;

    _log('--- User Info Check ---');
    _log('UID: ${_currentUser!.uid}');
    _log('Email: ${_currentUser!.email}');
    _log('Display Name: ${_currentUser!.displayName}');
    _log('Photo URL: ${_currentUser!.photoURL}');
    _log('Email Verified: ${_currentUser!.emailVerified}');
    _log('Is Anonymous: ${_currentUser!.isAnonymous}');
    _log(
      'Providers: ${_currentUser!.providerData.map((p) => p.providerId).join(", ")}',
    );
    _log('Metadata - Creation: ${_currentUser!.metadata.creationTime}');
    _log('Metadata - Last Sign In: ${_currentUser!.metadata.lastSignInTime}');
    _log('-----------------------');
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inner Voices'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _isLoading ? null : _signOut,
              tooltip: 'Sign out',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            _buildUserCard(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Debug Logs
            _buildLogPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    if (_currentUser == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Not signed in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Sign in with your Google account',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: _currentUser!.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              child: _currentUser!.photoURL == null
                  ? const Icon(Icons.person, size: 35)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser!.displayName ?? 'No name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.email ?? 'No email',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _currentUser!.emailVerified
                            ? Icons.verified
                            : Icons.warning,
                        size: 16,
                        color: _currentUser!.emailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentUser!.emailVerified
                            ? 'Verified'
                            : 'Not verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentUser!.emailVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentUser == null) {
      return ElevatedButton.icon(
        onPressed: _isInitialized ? _signInWithGoogle : null,
        icon: const Icon(Icons.login),
        label: Text(_isInitialized ? 'Sign in with Google' : 'Initializing...'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshToken,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Token'),
                ),
                ElevatedButton.icon(
                  onPressed: _checkUserInfo,
                  icon: const Icon(Icons.info),
                  label: const Text('Check User Info'),
                ),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debug Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('❌');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isError ? Colors.red : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
