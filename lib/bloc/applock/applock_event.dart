part of 'applock_bloc.dart';

@immutable
sealed class ApplockEvent {
  final BuildContext context;
  const ApplockEvent(this.context);
}

class ApplockInitialEvent extends ApplockEvent {
  const ApplockInitialEvent(super.context);
}

class ApplockLockEvent extends ApplockEvent {
  const ApplockLockEvent(super.context);
}

class ApplockUnlockEvent extends ApplockEvent {
  const ApplockUnlockEvent(super.context);
}

class ApplockSetPinEvent extends ApplockEvent {
  const ApplockSetPinEvent(super.context);
}

class ApplockShowWelcomeEvent extends ApplockEvent {
  const ApplockShowWelcomeEvent(super.context);
}

class ApplockChangePinEvent extends ApplockEvent {
  const ApplockChangePinEvent(super.context);
}

class ApplockVerifyForChangeEvent extends ApplockEvent {
  const ApplockVerifyForChangeEvent(super.context);
}
