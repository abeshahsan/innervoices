part of 'theme_bloc.dart';

@immutable
sealed class ThemeEvent {}

/// Load the saved theme preference from storage
final class ThemeLoadRequested extends ThemeEvent {}

/// Change the theme mode
final class ThemeChanged extends ThemeEvent {
  final AppThemeMode themeMode;

  ThemeChanged(this.themeMode);
}
