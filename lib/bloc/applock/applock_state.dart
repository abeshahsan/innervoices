part of 'applock_bloc.dart';

@immutable
sealed class ApplockState {}

final class ApplockInitial extends ApplockState {}

final class ApplockLocked extends ApplockState {}

final class ApplockUnlocked extends ApplockState {}

final class ApplockPinNotSet extends ApplockState {}

final class ApplockPinSet extends ApplockState {}

final class ApplockShowingWelcome extends ApplockState {}

final class ApplockSettingPin extends ApplockState {}

final class ApplockChangingPin extends ApplockState {}
