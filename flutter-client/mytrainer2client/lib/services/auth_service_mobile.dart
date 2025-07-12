// lib/services/auth_service_mobile.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OAuth2 / OIDC settings for your Keycloak realm and client.
const _issuer                = 'http://10.0.2.2:8081/realms/myrealm';
const _clientId              = 'mytrainer2client';
const _redirectUri           = 'com.mvfitness.mytrainer2client://oauthredirect';
const _postLogoutRedirectUri = 'com.mvfitness.mytrainer2client://logoutredirect';

/// A singleton service that manages:
///  • access & refresh tokens
///  • login / registration (authorize & exchange code)
///  • silent token refresh
///  • logout & token revocation
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FlutterAppAuth       _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? get accessToken => _accessToken;

  String? _refreshToken;
  String? _idToken;

  /// Reads any previously‐saved tokens from secure storage.
  Future<void> loadFromStorage() async {
    _accessToken  = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    _idToken      = await _storage.read(key: 'id_token');
    debugPrint('🔑 Loaded tokens: access=${_accessToken!=null}, refresh=${_refreshToken!=null}');
  }

  /// Interactive or silent login/signup via Keycloak.
  ///
  /// If [interactive] is `false`, attempts `prompt=none` to refresh silently.
  /// Returns `true` on success, `false` on error or user cancellation.
  Future<bool> loginOrSignup({bool interactive = true}) async {
    if (!interactive && _refreshToken == null) return false;

    final req = AuthorizationTokenRequest(
      _clientId,
      _redirectUri,
      discoveryUrl: '$_issuer/.well-known/openid-configuration',
      scopes: ['openid', 'profile', 'email', 'offline_access'],
      promptValues: interactive ? null : ['none'],
      allowInsecureConnections: true, // DEV ONLY; remove in prod
    );

    try {
      final res = await _appAuth.authorizeAndExchangeCode(req);
      if (res == null) return false;

      _accessToken  = res.accessToken;
      _idToken      = res.idToken;
      _refreshToken = res.refreshToken;

      // Save tokens
      await _storage.write(key: 'access_token',  value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'id_token',       value: _idToken);

      debugPrint('✅ Login success; tokens stored');
      return true;
    } catch (e, st) {
      debugPrint('⚠️ loginOrSignup error: $e\n$st');
      return false;
    }
  }

  /// Shortcut to show Keycloak’s “Register” screen.
  Future<bool> register(String u, String e, String p, String c) =>
      loginOrSignup(interactive: true);

  /// Uses the stored refresh token to obtain a fresh access token.
  ///
  /// Returns `true` on success (and updates in‐memory + stored tokens),
  /// or `false` if the refresh failed or no refresh token present.
  Future<bool> refresh() async {
    if (_refreshToken == null) return false;

    final req = TokenRequest(
      _clientId,
      _redirectUri,
      grantType: 'refresh_token',
      refreshToken: _refreshToken!,
      discoveryUrl: '$_issuer/.well-known/openid-configuration',
      scopes: ['openid', 'profile', 'email', 'offline_access'],
      allowInsecureConnections: true,
    );

    try {
      final res = await _appAuth.token(req);
      if (res == null) return false;

      _accessToken  = res.accessToken;
      _idToken      = res.idToken;
      _refreshToken = res.refreshToken ?? _refreshToken;

      await _storage.write(key: 'access_token',  value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'id_token',       value: _idToken);

      debugPrint('🔄 Refresh success');
      return true;
    } catch (e) {
      debugPrint('⚠️ refresh error: $e');
      return false;
    }
  }

  /// Returns a valid access token, loading from storage and/or refreshing if needed.
  ///
  /// 1. If no `_accessToken` in memory, calls [loadFromStorage].
  /// 2. Parses the JWT `exp` claim; if <1min to expiry, calls [refresh].
  /// 3. Returns the up‐to‐date token or `null` on any failure.
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) {
      await loadFromStorage();
      if (_accessToken == null) return null;
    }

    try {
      final parts = _accessToken!.split('.');
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);

      if (exp.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        final ok = await refresh();
        if (!ok) return null;
      }
    } catch (_) {
      final ok = await refresh();
      if (!ok) return null;
    }

    return _accessToken;
  }

  /// Logs out locally (clearing tokens) and at Keycloak (end‐session endpoint).
  ///
  /// Also optionally revokes the refresh token before redirecting.
  Future<void> logout() async {
    // Clear storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'id_token');
    _accessToken  = null;
    _refreshToken = null;
    _idToken      = null;
    debugPrint('🔒 Cleared tokens');

    // Optionally revoke refresh token
    if (_refreshToken != null) {
      try {
        await _appAuth.token(TokenRequest(
          _clientId,
          _redirectUri,
          grantType: 'refresh_token',
          refreshToken: _refreshToken!,
          discoveryUrl: '$_issuer/.well-known/openid-configuration',
          allowInsecureConnections: true,
        ));
        debugPrint('🔒 Revocation request sent');
      } catch (_) {}
    }

    // Redirect to Keycloak end-session
    try {
      await _appAuth.endSession(EndSessionRequest(
        idTokenHint: _idToken,
        postLogoutRedirectUrl: _postLogoutRedirectUri,
        allowInsecureConnections: true,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          endSessionEndpoint:
          'http://10.0.2.2:8081/realms/myrealm/protocol/openid-connect/logout',
          authorizationEndpoint: '',
          tokenEndpoint: '',
        ),
      ));
      debugPrint('🔒 endSession called');
    } catch (e, st) {
      debugPrint('⚠️ logout error: $e\n$st');
    }
  }
}
