// lib/services/auth_service_stub.dart

import 'dart:async';

/// A no-op AuthService implementation used when neither
/// dart:html nor dart:io variants apply.
///
/// All methods return `null` or `false`, making it safe for builds
/// that don’t require actual authentication logic.
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  /// Always `null` in this stub.
  String? get accessToken => null;
  String? get lastAuthError => null;

  /// No-op.
  void loadFromStorage() {}

  /// No-op async rehydrate.
  Future<void> reloadFromStorage() async {}

  /// Always returns `false`.
  Future<bool> loginOrSignup({bool interactive = true}) async => false;

  /// Always returns `false`.
  Future<bool> register(String u, String e, String p, String c) async => false;

  /// Always returns `false`.
  Future<bool> refreshSession() async => false;

  /// No-op.
  Future<void> logout({String? postLogoutRedirectPath}) async {}

  /// Always `null`.
  Future<String?> getValidAccessToken() async => null;
}
