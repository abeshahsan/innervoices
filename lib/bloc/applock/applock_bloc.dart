import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:innervoices/data/services/pin_service.dart';
import 'package:local_auth/local_auth.dart';

part 'applock_event.dart';
part 'applock_state.dart';

class ApplockBloc extends Bloc<ApplockEvent, ApplockState> {
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  ApplockBloc() : super(ApplockInitial()) {
    on<ApplockInitialEvent>(_handleAppLockInitialEvent);
    on<ApplockLockEvent>(_handleLockEvent);
    on<ApplockUnlockEvent>(_handleUnlockEvent);
    on<ApplockSetPinEvent>(_handleSetPinEvent);
    on<ApplockShowWelcomeEvent>(_handleShowWelcomeEvent);
    on<ApplockChangePinEvent>(_handleChangePinEvent);
    on<ApplockVerifyForChangeEvent>(_handleVerifyForChangeEvent);
  }

  /// Authenticate using biometrics (fingerprint/face)
  Future<bool> _authenticateWithBiometrics(BuildContext context) async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        debugPrint('Biometrics not available');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock',
      );

      if (didAuthenticate && context.mounted) {
        add(ApplockUnlockEvent(context));
      }

      return didAuthenticate;
    } catch (e) {
      debugPrint('Error using biometric authentication: $e');
      return false;
    }
  }

  /// Handle initial app lock setup
  Future<void> _handleAppLockInitialEvent(
    ApplockInitialEvent event,
    Emitter<ApplockState> emit,
  ) async {
    bool isPinSet = await _pinService.isPinSet();
    // Use addPostFrameCallback to show dialogs after the current frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (event.context.mounted) {
        if (isPinSet) {
          add(ApplockLockEvent(event.context));
        } else {
          add(ApplockShowWelcomeEvent(event.context));
        }
      }
    });
  }

  /// Handle showing welcome screen for first-time users
  Future<void> _handleShowWelcomeEvent(
    ApplockShowWelcomeEvent event,
    Emitter<ApplockState> emit,
  ) async {
    emit(ApplockShowingWelcome());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (event.context.mounted) {
        add(ApplockSetPinEvent(event.context));
      }
    });
  }

  /// Handle lock screen display with PIN verification
  Future<void> _handleLockEvent(
    ApplockLockEvent event,
    Emitter<ApplockState> emit,
  ) async {
    emit(ApplockLocked());
    String? pin = await _pinService.getPin();

    if (event.context.mounted) {
      screenLock(
        context: event.context,
        correctString: pin ?? '',
        onUnlocked: () {
          if (event.context.mounted) {
            add(ApplockUnlockEvent(event.context));
          }
        },
        customizedButtonChild: const Icon(Icons.fingerprint),
        customizedButtonTap: () async {
          await _authenticateWithBiometrics(event.context);
        },
      );
    }
  }

  /// Handle unlock event
  Future<void> _handleUnlockEvent(
    ApplockUnlockEvent event,
    Emitter<ApplockState> emit,
  ) async {
    emit(ApplockUnlocked());
  }

  /// Handle PIN creation for first-time setup (no biometric option)
  Future<void> _handleSetPinEvent(
    ApplockSetPinEvent event,
    Emitter<ApplockState> emit,
  ) async {
    emit(ApplockSettingPin());

    if (event.context.mounted) {
      screenLockCreate(
        context: event.context,
        onConfirmed: (newPin) async {
          await _pinService.savePin(newPin);
          if (event.context.mounted) {
            add(ApplockLockEvent(event.context));
          }
        },
        canCancel: false,
        digits: 4,
      );
    }
  }

  /// Handle verification before allowing PIN change (with biometric option)
  Future<void> _handleVerifyForChangeEvent(
    ApplockVerifyForChangeEvent event,
    Emitter<ApplockState> emit,
  ) async {
    String? pin = await _pinService.getPin();

    if (event.context.mounted) {
      screenLock(
        context: event.context,
        correctString: pin ?? '',
        onUnlocked: () {
          if (event.context.mounted) {
            Navigator.of(event.context).pop();
            add(ApplockChangePinEvent(event.context));
          }
        },
        customizedButtonChild: const Icon(Icons.fingerprint),
        customizedButtonTap: () async {
          final authenticated = await _authenticateWithBiometrics(
            event.context,
          );
          if (authenticated && event.context.mounted) {
            Navigator.of(event.context).pop();
            add(ApplockChangePinEvent(event.context));
          }
        },
      );
    }
  }

  /// Handle PIN change process
  Future<void> _handleChangePinEvent(
    ApplockChangePinEvent event,
    Emitter<ApplockState> emit,
  ) async {
    emit(ApplockChangingPin());

    if (event.context.mounted) {
      screenLockCreate(
        context: event.context,
        onConfirmed: (newPin) async {
          await _pinService.savePin(newPin);
          if (event.context.mounted) {
            Navigator.of(event.context).pop();
            ScaffoldMessenger.of(event.context).showSnackBar(
              const SnackBar(content: Text('PIN changed successfully')),
            );
          }
        },
        canCancel: true,
        onCancelled: () {
          if (event.context.mounted) {
            Navigator.of(event.context).pop();
          }
        },
        digits: 4,
      );
    }
  }
}
