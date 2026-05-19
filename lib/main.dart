import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/amplify_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const ProviderScope(child: GlazeVaultApp()));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
    safePrint('Amplify configured');
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify already configured — hot reload');
  } catch (e) {
    // Placeholder config will fail here — app continues, auth fails gracefully
    safePrint('Amplify configuration failed: $e');
  }
}
