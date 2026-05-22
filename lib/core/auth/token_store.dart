import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_provider.dart';
import 'glaze_user.dart';

part 'token_store.g.dart';

const _kIdToken = 'auth_id_token';
const _kAccessToken = 'auth_access_token';
const _kRefreshToken = 'auth_refresh_token';
const _kExpiry = 'auth_expiry';

class TokenStore {
  TokenStore(this._prefs);
  final SharedPreferences _prefs;

  String? get idToken => _prefs.getString(_kIdToken);
  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);

  bool get hasToken => idToken != null && idToken!.isNotEmpty;

  bool get isExpired {
    final exp = _prefs.getString(_kExpiry);
    if (exp == null) return true;
    final expiry = DateTime.tryParse(exp);
    if (expiry == null) return true;
    // Consider expired one minute early to avoid edge-case 401s.
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 1)));
  }

  bool get hasValidToken => hasToken && !isExpired;

  GlazeUser? get user {
    final token = idToken;
    if (token == null) return null;
    return GlazeUser.fromIdToken(token);
  }

  Future<void> save({
    required String idToken,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiry =
        DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
    await _prefs.setString(_kIdToken, idToken);
    await _prefs.setString(_kAccessToken, accessToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
    await _prefs.setString(_kExpiry, expiry);
  }

  Future<void> clear() async {
    await _prefs.remove(_kIdToken);
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kExpiry);
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(TokenStoreRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStore(prefs);
}
