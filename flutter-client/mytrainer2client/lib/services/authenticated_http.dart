library;

import 'dart:convert';

import 'package:http/http.dart' as base_http;

import 'auth_service.dart';
import 'auth_session_manager.dart';

export 'package:http/http.dart' show Response;

class SessionExpiredException implements Exception {
  const SessionExpiredException([this.message = 'Your session has expired.']);

  final String message;

  @override
  String toString() => message;
}

final AuthService _auth = AuthService();

Future<Map<String, String>> authorizedHeaders({
  Map<String, String>? headers,
  bool includeJsonContentType = false,
  bool includeJsonAccept = false,
}) async {
  if (AuthSessionManager.instance.isSessionExpired) {
    throw const SessionExpiredException();
  }

  final token = await _auth.getValidAccessToken();
  if (token == null || token.isEmpty) {
    await _expireSession();
    throw const SessionExpiredException();
  }

  return {
    ...?headers,
    'Authorization': 'Bearer $token',
    if (includeJsonAccept) 'Accept': 'application/json',
    if (includeJsonContentType) 'Content-Type': 'application/json',
  };
}

Future<base_http.Response> get(
  Uri url, {
  Map<String, String>? headers,
}) {
  return _sendWithRefresh(
    headers: headers,
    send: (resolvedHeaders) => base_http.get(url, headers: resolvedHeaders),
  );
}

Future<base_http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _sendWithRefresh(
    headers: headers,
    send: (resolvedHeaders) => base_http.post(
      url,
      headers: resolvedHeaders,
      body: body,
      encoding: encoding,
    ),
  );
}

Future<base_http.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _sendWithRefresh(
    headers: headers,
    send: (resolvedHeaders) => base_http.put(
      url,
      headers: resolvedHeaders,
      body: body,
      encoding: encoding,
    ),
  );
}

Future<base_http.Response> delete(
  Uri url, {
  Map<String, String>? headers,
}) {
  return _sendWithRefresh(
    headers: headers,
    send: (resolvedHeaders) => base_http.delete(
      url,
      headers: resolvedHeaders,
    ),
  );
}

Future<base_http.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _sendWithRefresh(
    headers: headers,
    send: (resolvedHeaders) => base_http.patch(
      url,
      headers: resolvedHeaders,
      body: body,
      encoding: encoding,
    ),
  );
}

Future<base_http.Response> _sendWithRefresh({
  required Map<String, String>? headers,
  required Future<base_http.Response> Function(Map<String, String>? headers) send,
}) async {
  if (_isSessionBlocked(headers)) {
    throw const SessionExpiredException();
  }

  final initialResponse = await send(headers);
  if (!_shouldRefresh(initialResponse, headers)) {
    return initialResponse;
  }

  final refreshed = await _auth.refreshSession();
  if (!refreshed) {
    await _expireSession();
    throw const SessionExpiredException();
  }

  final refreshedHeaders = await _updatedAuthHeaders(headers);
  final retryResponse = await send(refreshedHeaders);
  if (_shouldRefresh(retryResponse, refreshedHeaders)) {
    await _expireSession();
    throw const SessionExpiredException();
  }

  return retryResponse;
}

bool _isSessionBlocked(Map<String, String>? headers) {
  if (!AuthSessionManager.instance.isSessionExpired) return false;
  return _hasAuthorizationHeader(headers);
}

bool _shouldRefresh(base_http.Response response, Map<String, String>? headers) {
  if (!_hasAuthorizationHeader(headers)) return false;
  return response.statusCode == 401 || response.statusCode == 403;
}

bool _hasAuthorizationHeader(Map<String, String>? headers) {
  if (headers == null) return false;

  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'authorization' &&
        entry.value.trim().isNotEmpty) {
      return true;
    }
  }

  return false;
}

Future<Map<String, String>> _updatedAuthHeaders(
  Map<String, String>? headers,
) async {
  final token = await _auth.getValidAccessToken();
  if (token == null || token.isEmpty) {
    await _expireSession();
    throw const SessionExpiredException();
  }

  return {
    ...?headers,
    'Authorization': 'Bearer $token',
  };
}

Future<void> _expireSession() async {
  await _auth.expireSession();
  await AuthSessionManager.instance.markSessionExpired();
}
