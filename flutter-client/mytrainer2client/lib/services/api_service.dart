// lib/services/api_service.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service_mobile.dart';

/// A thin wrapper around HTTP GET that automatically handles:
///  • loading the current access token
///  • refreshing it if expired
///  • attaching the `Authorization: Bearer` header
///  • returning the response body or `null` on failure
class ApiService {
  /// Base URL for your Spring Boot backend.
  static const _baseUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  /// Underlying auth service (singleton) for token management.
  final AuthService _auth = AuthService();

  /// Fetches a secure endpoint at [path], returning the response body.
  ///
  /// 1. Calls [_auth.getValidAccessToken], which loads from storage or
  ///    silently refreshes if close to expiry.
  /// 2. If no token is available, returns `null`.
  /// 3. Otherwise sends `GET $_baseUrl$path` with header
  ///       `Authorization: Bearer <token>`.
  /// 4. Returns `res.body` on HTTP 200, else `null`.
  Future<String?> fetchSecure(String path) async {
    final token = await _auth.getValidAccessToken();
    if (token == null) return null;

    final uri = Uri.parse('$_baseUrl$path');
    try {
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200 ? res.body : null;
    } catch (e) {
      debugPrint('❌ fetchSecure error: $e');
      return null;
    }
  }
}
