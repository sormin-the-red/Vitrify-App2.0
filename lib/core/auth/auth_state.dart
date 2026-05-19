import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
