import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A cached GET response body with the time it was stored.
class CachedResponse {
  const CachedResponse({required this.body, required this.savedAt});
  final String body;
  final DateTime savedAt;
}

/// SharedPreferences-backed write-through cache for GET responses, keyed by
/// request path. Web-compatible (localStorage) — this is deliberately not
/// sqflite so one implementation covers all platforms; entries are a single
/// user's lists/details and stay small.
class ResponseCache {
  static const _prefix = 'rc:';

  Future<void> put(String path, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$path',
        jsonEncode({
          'b': body,
          't': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (_) {
      // Caching is best-effort — never let it break a live request.
    }
  }

  Future<CachedResponse?> get(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$path');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedResponse(
        body: decoded['b'] as String,
        savedAt:
            DateTime.tryParse(decoded['t'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
