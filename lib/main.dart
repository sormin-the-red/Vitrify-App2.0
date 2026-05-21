import 'dart:async';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/amplify_config.dart';
import 'core/settings/settings_provider.dart';

void main() {
  // Flutter web (DDC/debug mode) fires a spurious zone-level DartError from the
  // engine when Chrome resizes before physicalSize stabilises. The assertion is
  // stripped in release builds; swallow it in debug so the red-screen never shows.
  runZonedGuarded(_main, (error, _) {
    if (error.toString().contains('ViewInsets cannot be negative')) return;
    FlutterError.reportError(FlutterErrorDetails(exception: error));
  });
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('ViewInsets cannot be negative')) {
      return;
    }
    FlutterError.presentError(details);
  };

  final prefs = await SharedPreferences.getInstance();
  await _configureAmplify();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const GlazeVaultApp(),
  ));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
    safePrint('Amplify configured');
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify already configured — hot reload');
  } catch (e) {
    safePrint('Amplify configuration failed: $e');
  }
}
