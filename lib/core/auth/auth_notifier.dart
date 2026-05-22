import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state.dart';
import 'glaze_user.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _checkCurrentUser();
    return const AuthLoading();
  }

  Future<void> _checkCurrentUser() async {
    debugPrint('[GlazeVault] _checkCurrentUser: isConfigured=${Amplify.isConfigured}');
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      debugPrint('[GlazeVault] fetchAuthSession: isSignedIn=${session.isSignedIn}');
      if (session.isSignedIn) {
        final idToken = session.userPoolTokensResult.value.idToken.raw;
        final user = GlazeUser.fromIdToken(idToken);
        debugPrint('[GlazeVault] user=${user?.email}');
        if (user != null) {
          state = AuthAuthenticated(user);
          return;
        }
      }
    } on SignedOutException {
      debugPrint('[GlazeVault] Not signed in');
    } catch (e) {
      debugPrint('[GlazeVault] fetchAuthSession error: $e');
    }
    state = const AuthUnauthenticated();
  }

  // ── Email / password ────────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    final result =
        await Amplify.Auth.signIn(username: email, password: password);
    if (result.isSignedIn) {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken.raw;
      final user = GlazeUser.fromIdToken(idToken) ??
          GlazeUser(userId: email, email: email);
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

  // ── Social / OAuth ──────────────────────────────────────────────────────────

  /// Initiates social sign-in via Cognito hosted UI.
  /// [provider] is 'Google' or 'Facebook'.
  /// On web this causes a full page navigation; auth state is set on the
  /// return trip when configure() processes the ?code= callback.
  Future<void> signInWithSocial(String provider) async {
    final authProvider = switch (provider) {
      'Facebook' => AuthProvider.facebook,
      _ => AuthProvider.google,
    };
    await Amplify.Auth.signInWithWebUI(provider: authProvider);
    // Reached on mobile after WebView closes; on web the page navigates away
    // so this line is never hit — auth state is restored in _checkCurrentUser().
    await _checkCurrentUser();
  }

  // ── Sign out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Amplify.Auth.signOut();
    state = const AuthUnauthenticated();
  }
}
