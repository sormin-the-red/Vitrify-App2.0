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
  final String defaultCone;
  final String defaultFiringType;
  final String defaultApplicationMethod;
  final String defaultAtmosphere;

  const AppSettings({
    required this.themeMode,
    required this.startupTab,
    required this.defaultCone,
    required this.defaultFiringType,
    required this.defaultApplicationMethod,
    required this.defaultAtmosphere,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? startupTab,
    String? defaultCone,
    String? defaultFiringType,
    String? defaultApplicationMethod,
    String? defaultAtmosphere,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        startupTab: startupTab ?? this.startupTab,
        defaultCone: defaultCone ?? this.defaultCone,
        defaultFiringType: defaultFiringType ?? this.defaultFiringType,
        defaultApplicationMethod:
            defaultApplicationMethod ?? this.defaultApplicationMethod,
        defaultAtmosphere: defaultAtmosphere ?? this.defaultAtmosphere,
      );
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const _themeModeKey              = 'settings_theme_mode';
  static const _startupTabKey             = 'settings_startup_tab';
  static const _defaultConeKey            = 'settings_default_cone';
  static const _defaultFiringKey          = 'settings_default_firing_type';
  static const _defaultApplicationMethod  = 'settings_default_application_method';
  static const _defaultAtmosphereKey      = 'settings_default_atmosphere';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values[
          prefs.getInt(_themeModeKey) ?? ThemeMode.system.index],
      startupTab: prefs.getString(_startupTabKey) ?? '/feed',
      defaultCone: prefs.getString(_defaultConeKey) ?? '6',
      defaultFiringType: prefs.getString(_defaultFiringKey) ?? 'Oxidation',
      defaultApplicationMethod:
          prefs.getString(_defaultApplicationMethod) ?? 'Dip',
      defaultAtmosphere: prefs.getString(_defaultAtmosphereKey) ?? '',
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

  Future<void> setDefaultCone(String cone) async {
    await _prefs.setString(_defaultConeKey, cone);
    ref.invalidateSelf();
  }

  Future<void> setDefaultFiringType(String type) async {
    await _prefs.setString(_defaultFiringKey, type);
    ref.invalidateSelf();
  }

  Future<void> setDefaultApplicationMethod(String method) async {
    await _prefs.setString(_defaultApplicationMethod, method);
    ref.invalidateSelf();
  }

  Future<void> setDefaultAtmosphere(String atmosphere) async {
    await _prefs.setString(_defaultAtmosphereKey, atmosphere);
    ref.invalidateSelf();
  }
}
