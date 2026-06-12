import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/response_cache.dart';

part 'api_client.g.dart';

const _baseUrl = 'https://a2gcaf5uqj.execute-api.us-east-2.amazonaws.com';

/// Header present on responses served from the offline cache, so UI layers
/// can surface a "showing offline copy" hint if they want to.
const kFromCacheHeader = 'x-vitrify-from-cache';

class ApiClient {
  final ResponseCache _cache = ResponseCache();

  /// GETs are write-through cached; on any network/auth failure the cached
  /// copy (when present) is served instead so the app keeps working in
  /// studios with no connectivity. Paginated requests (cursor in the URL)
  /// are not cached to keep the store bounded.
  Future<http.Response> get(String path) async {
    final cacheable = !path.contains('cursor=');
    try {
      final res = await http.get(_uri(path), headers: await _headers());
      if (cacheable && res.statusCode == 200) {
        // Fire-and-forget — never block the live response on the cache.
        // ignore: unawaited_futures
        _cache.put(path, res.body);
      }
      return res;
    } catch (_) {
      if (cacheable) {
        final cached = await _cache.get(path);
        if (cached != null) {
          return http.Response(
            cached.body,
            200,
            headers: {
              // charset matters: http.Response defaults to latin1 otherwise,
              // which garbles non-ASCII recipe names on decode.
              'content-type': 'application/json; charset=utf-8',
              kFromCacheHeader: cached.savedAt.toIso8601String(),
            },
          );
        }
      }
      rethrow;
    }
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    return http.post(_uri(path),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    return http.put(_uri(path),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> delete(String path) async {
    return http.delete(_uri(path), headers: await _headers());
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, String>> _headers() async {
    final token = await _idToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> _idToken() async {
    final session =
        await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session.userPoolTokensResult.value.idToken.raw;
  }
}

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();
