import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> localAuth(BuildContext context) async {
      final localAuth = LocalAuthentication();

      try {
        final didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate',
        );

        if (didAuthenticate && context.mounted) {
          AppLock.of(context)!.didUnlock();
        }
      } catch (e) {
        debugPrint('Error using local authentication: $e');
      }
    }

    return ScreenLock(
      correctString: '1234', // Replace with your desired PIN
      title: const Text('Enter PIN to unlock', style: TextStyle(fontSize: 24)),
      customizedButtonChild: const Icon(Icons.fingerprint, size: 42),
      customizedButtonTap: () => localAuth(context),
      onOpened: () => localAuth(context),
      onUnlocked: () {
        AppLock.of(context)!.didUnlock();
      },
    );
  }
}
