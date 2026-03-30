// lib/services/api_service.dart

import 'package:flutter/foundation.dart';

import 'authenticated_http.dart' as http;
import 'app_config.dart';

/// A thin wrapper around HTTP GET that automatically handles:
///  • loading the current access token
///  • refreshing it if expired
///  • attaching the `Authorization: Bearer` header
///  • returning the response body or `null` on failure
class ApiService {
  /// Base URL for your Spring Boot backend.
  static final _baseUrl = AppConfig.apiBaseUrl;

  /// Fetches a secure endpoint at [path], returning the response body.
  ///
  /// 1. Calls [_auth.getValidAccessToken], which loads from storage or
  ///    silently refreshes if close to expiry.
  /// 2. If no token is available, returns `null`.
  /// 3. Otherwise sends `GET $_baseUrl$path` with header
  ///       `Authorization: Bearer <token>`.
  /// 4. Returns `res.body` on HTTP 200, else `null`.
  Future<String?> fetchSecure(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final res = await http.get(
        uri,
        headers: await http.authorizedHeaders(),
      );
      return res.statusCode == 200 ? res.body : null;
    } catch (e) {
      debugPrint('❌ fetchSecure error: $e');
      return null;
    }
  }
}
