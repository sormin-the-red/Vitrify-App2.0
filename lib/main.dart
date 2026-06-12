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
  // Swallow the spurious DartError from the engine on Chrome resize before
  // physicalSize stabilises — stripped in release builds.
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
    debugPrint('[GlazeVault] Amplify configured');
  } on AmplifyAlreadyConfiguredException {
    debugPrint('[GlazeVault] Amplify already configured');
  } catch (e) {
    final msg = e.toString();
    debugPrint('[GlazeVault] configure() error: $msg');

    // During a social (Google/Facebook) sign-in OAuth callback, Amplify
    // exchanges the auth code for tokens (stored in IndexedDB) and then
    // tries to sync the email attribute. Cognito rejects that update for
    // federated users, so configure() throws — but the tokens are valid.
    //
    // The OAuth code is now consumed and gone from the URL. A second
    // configure() call skips the token exchange entirely and just finishes
    // setting up the plugins, leaving Amplify.isConfigured=true so that
    // _checkCurrentUser() can call fetchAuthSession() successfully.
    if (msg.contains('cannot be updated') || msg.contains('Attribute cannot')) {
      debugPrint('[GlazeVault] Social sign-in attribute sync failed — attempting recovery configure');
      try {
        await Amplify.configure(amplifyConfig);
        debugPrint('[GlazeVault] Recovery configure succeeded');
      } on AmplifyAlreadyConfiguredException {
        debugPrint('[GlazeVault] Amplify already configured (recovery path)');
      } catch (e2) {
        debugPrint('[GlazeVault] Recovery configure failed: $e2');
      }
    }
  }
}
