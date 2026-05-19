import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

// Initialized in main.dart and overridden in ProviderScope
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) =>
    throw UnimplementedError();

class AppSettings {
  final ThemeMode themeMode;
  final String startupTab;

  const AppSettings({required this.themeMode, required this.startupTab});

  AppSettings copyWith({ThemeMode? themeMode, String? startupTab}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        startupTab: startupTab ?? this.startupTab,
      );
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const _themeModeKey = 'settings_theme_mode';
  static const _startupTabKey = 'settings_startup_tab';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values[prefs.getInt(_themeModeKey) ?? ThemeMode.system.index],
      startupTab: prefs.getString(_startupTabKey) ?? '/feed',
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeModeKey, mode.index);
    ref.invalidateSelf();
  }

  Future<void> setStartupTab(String tab) async {
    await _prefs.setString(_startupTabKey, tab);
    ref.invalidateSelf();
  }
}
