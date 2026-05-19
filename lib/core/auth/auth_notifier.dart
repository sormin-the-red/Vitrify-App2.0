import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _checkCurrentUser();
    return const AuthLoading();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      state = AuthAuthenticated(user);
    } on SignedOutException {
      state = const AuthUnauthenticated();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn(String email, String password) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    if (result.isSignedIn) {
      final user = await Amplify.Auth.getCurrentUser();
      state = AuthAuthenticated(user);
    }
  }

  Future<void> signUp(String email, String password) async {
    await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(userAttributes: {
        CognitoUserAttributeKey.email: email,
      }),
    );
  }

  Future<void> confirmSignUp(String email, String code) async {
    final result = await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
    if (result.isSignUpComplete) {
      await _checkCurrentUser();
    }
  }

  // TODO: Platform setup required before social sign-in works.
  // Android: add intent-filter for vitrify://callback in AndroidManifest.xml
  // iOS: add vitrify URL scheme to Info.plist
  Future<void> signInWithSocial(AuthProvider provider) async {
    await Amplify.Auth.signInWithWebUI(provider: provider);
    final user = await Amplify.Auth.getCurrentUser();
    state = AuthAuthenticated(user);
  }

  Future<void> signOut() async {
    await Amplify.Auth.signOut();
    state = const AuthUnauthenticated();
  }
}
