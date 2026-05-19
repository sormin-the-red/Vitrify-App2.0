import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

// TODO: Replace with ApiUrl output from `cdk deploy`
const _baseUrl = 'REPLACE_WITH_API_GATEWAY_URL';

class ApiClient {
  Future<http.Response> get(String path) async {
    return http.get(_uri(path), headers: await _headers());
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
