import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:innervoices/components/appbar.dart';
import 'package:innervoices/services/google_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) {
        if (mounted) {
          setState(() => _currentUser = user);
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to initialize: $e');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        _showSuccessSnackbar(
          'Welcome, ${userCredential.user?.displayName ?? 'User'}!',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Sign in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      appBar: BrandAppbar(title: 'Inner Voices'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo/Title
            const Icon(Icons.psychology, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'Inner Voices',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with your thoughts',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            _buildSignInSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInSection() {
    return Column(
      children: [
        const Text(
          'Sign in to get started',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.asset(
                  'assets/google_logo.png', // You'll need to add this asset
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.login, size: 20);
                  },
                ),
          label: Text(
            _isLoading ? 'Signing In...' : 'Sign in with Google',
            style: const TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
