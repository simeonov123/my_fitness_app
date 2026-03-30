// lib/services/auth_service_mobile.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_config.dart';

/// OAuth2 / OIDC settings for your Keycloak realm and client.
final _issuer = AppConfig.keycloakRealmUrl;
const _clientId = AppConfig.oidcClientId;
const _redirectUri = AppConfig.mobileRedirectUri;
const _postLogoutRedirectUri = AppConfig.mobilePostLogoutRedirectUri;

/// A singleton service that manages:
///  • access & refresh tokens
///  • login / registration (authorize & exchange code)
///  • silent token refresh
///  • logout & token revocation
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? get accessToken => _accessToken;

  String? _refreshToken;
  String? _idToken;
  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;
  Future<bool>? _refreshInFlight;

  /// Reads any previously‐saved tokens from secure storage.
  Future<void> loadFromStorage() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    _idToken = await _storage.read(key: 'id_token');
    debugPrint(
        '🔑 Loaded tokens: access=${_accessToken != null}, refresh=${_refreshToken != null}');
  }

  Future<void> reloadFromStorage() => loadFromStorage();

  /// Interactive or silent login/signup via Keycloak.
  ///
  /// If [interactive] is `false`, attempts `prompt=none` to refresh silently.
  /// Returns `true` on success, `false` on error or user cancellation.
  Future<bool> loginOrSignup({bool interactive = true}) async {
    if (!interactive && _refreshToken == null) return false;
    _lastAuthError = null;

    final req = AuthorizationTokenRequest(
      _clientId,
      _redirectUri,
      discoveryUrl: '$_issuer/.well-known/openid-configuration',
      scopes: ['openid', 'profile', 'email', 'offline_access'],
      promptValues: interactive ? null : ['none'],
      allowInsecureConnections: AppConfig.allowInsecureConnections,
    );

    try {
      final res = await _appAuth.authorizeAndExchangeCode(req);
      if (res == null) return false;

      _accessToken = res.accessToken;
      _idToken = res.idToken;
      _refreshToken = res.refreshToken;

      // Save tokens
      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'id_token', value: _idToken);

      debugPrint('✅ Login success; tokens stored');
      return true;
    } on PlatformException catch (e, st) {
      _lastAuthError =
          'PlatformException(${e.code}): ${e.message ?? e.details ?? e.toString()}';
      debugPrint('⚠️ loginOrSignup platform error: $_lastAuthError\n$st');
      return false;
    } catch (e, st) {
      _lastAuthError = e.toString();
      debugPrint('⚠️ loginOrSignup error: $e\n$st');
      return false;
    }
  }

  /// Shortcut to show Keycloak’s “Register” screen.
  Future<bool> register(String u, String e, String p, String c) =>
      loginOrSignup(interactive: true);

  Future<bool> refreshSession() async {
    await loadFromStorage();
    return refresh();
  }

  /// Uses the stored refresh token to obtain a fresh access token.
  ///
  /// Returns `true` on success (and updates in‐memory + stored tokens),
  /// or `false` if the refresh failed or no refresh token present.
  Future<bool> refresh() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _performRefresh();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<bool> _performRefresh() async {
    if (_refreshToken == null) return false;

    final req = TokenRequest(
      _clientId,
      _redirectUri,
      grantType: 'refresh_token',
      refreshToken: _refreshToken!,
      discoveryUrl: '$_issuer/.well-known/openid-configuration',
      scopes: ['openid', 'profile', 'email', 'offline_access'],
      allowInsecureConnections: AppConfig.allowInsecureConnections,
    );

    try {
      final res = await _appAuth.token(req);
      if (res == null) return false;

      _accessToken = res.accessToken;
      _idToken = res.idToken;
      _refreshToken = res.refreshToken ?? _refreshToken;

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'id_token', value: _idToken);

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

  Future<void> expireSession() async {
    _accessToken = null;
    await _storage.delete(key: 'access_token');
  }

  /// Logs out locally (clearing tokens) and at Keycloak (end‐session endpoint).
  ///
  /// Also optionally revokes the refresh token before redirecting.
  Future<void> logout({String? postLogoutRedirectPath}) async {
    final refreshToken = _refreshToken;
    final idTokenHint = _idToken;

    // Clear storage aggressively so stale invite/auth state does not survive logout.
    await _storage.deleteAll();
    _accessToken = null;
    _refreshToken = null;
    _idToken = null;
    debugPrint('🔒 Cleared tokens and secure storage');

    // Optionally revoke refresh token
    if (refreshToken != null) {
      try {
        await _appAuth.token(TokenRequest(
          _clientId,
          _redirectUri,
          grantType: 'refresh_token',
          refreshToken: refreshToken,
          discoveryUrl: '$_issuer/.well-known/openid-configuration',
          allowInsecureConnections: AppConfig.allowInsecureConnections,
        ));
        debugPrint('🔒 Revocation request sent');
      } catch (_) {}
    }

    // Redirect to Keycloak end-session
    try {
      await _appAuth.endSession(EndSessionRequest(
        idTokenHint: idTokenHint,
        postLogoutRedirectUrl: _postLogoutRedirectUri,
        allowInsecureConnections: AppConfig.allowInsecureConnections,
        serviceConfiguration: AuthorizationServiceConfiguration(
          endSessionEndpoint: AppConfig.keycloakLogoutUrl,
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
