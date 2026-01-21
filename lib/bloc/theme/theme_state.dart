part of 'theme_bloc.dart';

@immutable
class ThemeState {
  final AppThemeMode themeMode;

  const ThemeState({required this.themeMode});

  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
}
