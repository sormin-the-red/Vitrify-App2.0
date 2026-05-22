import 'dart:convert';

class GlazeUser {
  final String userId;
  final String email;

  const GlazeUser({required this.userId, required this.email});

  // Mirrors Amplify's AuthUser.username — used by profile_screen for display.
  String get username => email;

  static GlazeUser? fromIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final claims =
          jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
      final sub = claims['sub'] as String?;
      if (sub == null || sub.isEmpty) return null;
      final email = (claims['email'] as String?) ??
          (claims['cognito:username'] as String?) ??
          '';
      return GlazeUser(userId: sub, email: email);
    } catch (_) {
      return null;
    }
  }
}
