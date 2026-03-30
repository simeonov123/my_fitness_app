/// Web-only AuthService implementation.
/// Uses `openid_client` + an iframe redirect for silent renew.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';

import 'app_config.dart';

/// Common interface shared by all platform-specific services.
abstract class _AuthServiceBase {
  String? get accessToken;

  /// Read any tokens cached in localStorage/secure storage.
  void loadFromStorage();

  /// Rehydrate any stored tokens and update in-memory state.
  Future<void> reloadFromStorage();

  /// Start a login / signup flow.
  Future<bool> loginOrSignup({bool interactive = true});

  /// Shortcut for “Register” (falls back to normal login flow on web).
  Future<bool> register(String u, String e, String p, String c);

  /// Refresh the current session without requiring a new interactive login.
  Future<bool> refreshSession();

  /// Clear local tokens and call the Keycloak end-session endpoint.
  Future<void> logout({String? postLogoutRedirectPath});

  /// Remove the local access token after an unrecoverable session failure.
  Future<void> expireSession();

  /// Return a **currently valid** JWT, silently refreshing if needed.
  Future<String?> getValidAccessToken();
}

class AuthService implements _AuthServiceBase {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // ===== Keycloak config (DEV — adjust for prod) ============================
  static final issuerUrl = AppConfig.keycloakRealmUrl;

  static const clientId = AppConfig.oidcClientId;
  static String get redirect {
    final uri = Uri.parse(html.window.location.href);
    final normalized = uri.replace(
      queryParameters: null,
      fragment: '',
    );
    return normalized.toString();
  }

  static const _credentialStorageKey = 'oidc_credential';
  static const _pkceStateStorageKey = 'oidc_pkce_state';
  static const _pkceVerifierStorageKey = 'oidc_pkce_verifier';
  static const _pkceRedirectUriStorageKey = 'oidc_pkce_redirect_uri';

  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  String? _lastAuthError;
  String? _storedCredentialJson;
  Credential? _credential;
  StreamSubscription<TokenResponse>? _tokenChangedSubscription;
  Future<bool>? _silentLoginInFlight;

  @override
  String? get accessToken => _accessToken;
  String? get lastAuthError => _lastAuthError;

  // --------------------------------------------------------------------------
  // Storage helpers
  // --------------------------------------------------------------------------
  @override
  void loadFromStorage() {
    _accessToken = html.window.localStorage['access_token'];
    _idToken = html.window.localStorage['id_token'];
    _refreshToken = html.window.localStorage['refresh_token'];
    _storedCredentialJson = html.window.localStorage[_credentialStorageKey];

    if ((_refreshToken == null || _refreshToken!.isEmpty) &&
        _storedCredentialJson != null &&
        _storedCredentialJson!.isNotEmpty) {
      try {
        final credentialJson =
            jsonDecode(_storedCredentialJson!) as Map<String, dynamic>;
        _refreshToken = _findRefreshToken(credentialJson);
      } catch (_) {}
    }
  }

  @override
  Future<void> reloadFromStorage() async {
    loadFromStorage();
  }

  // --------------------------------------------------------------------------
  // Login / signup (interactive OR silent)
  // --------------------------------------------------------------------------
  @override
  Future<bool> loginOrSignup({bool interactive = true}) async {
    if (!interactive) {
      final inFlight = _silentLoginInFlight;
      if (inFlight != null) return inFlight;

      final future = _performLogin(interactive: false);
      _silentLoginInFlight = future;
      try {
        return await future;
      } finally {
        if (identical(_silentLoginInFlight, future)) {
          _silentLoginInFlight = null;
        }
      }
    }

    return _performLogin(interactive: true);
  }

  Future<bool> _performLogin({required bool interactive}) async {
    _lastAuthError = null;
    try {
      if (!interactive && _hasValidAccessToken()) {
        return true;
      }

      final issuer = await Issuer.discover(Uri.parse(issuerUrl));
      final client = Client(issuer, clientId);

      if (!interactive) {
        final refreshed = await _refreshWithStoredRefreshToken(
          issuer.metadata.tokenEndpoint.toString(),
        );
        if (refreshed) return true;

        final restored = await _refreshStoredCredential(client);
        if (restored) return true;

        // Silent auth on web should never yank the user out to Keycloak unless
        // we are already handling an auth callback.
        if (!_hasAuthCallback()) {
          return false;
        }
      }

      if (interactive && !_hasAuthCallback()) {
        _startInteractiveLogin(client);
        return false;
      }

      final cred = await _completeAuthorizationCodeLogin(client);
      if (cred == null) {
        return false;
      }

      final token = await cred.getTokenResponse();
      await _persistCredential(cred, token);
      return true;
    } catch (e) {
      _lastAuthError = e.toString();
      return false;
    }
  }

  void _startInteractiveLogin(Client client) {
    final redirectUri = redirect;
    final state = _randomString(20);
    final codeVerifier = _randomString(64);
    final flow = Flow.authorizationCodeWithPKCE(
      client,
      state: state,
      codeVerifier: codeVerifier,
      scopes: const ['openid', 'profile', 'email', 'offline_access'],
    )..redirectUri = Uri.parse(redirectUri);

    html.window.sessionStorage[_pkceStateStorageKey] = state;
    html.window.sessionStorage[_pkceVerifierStorageKey] = codeVerifier;
    html.window.sessionStorage[_pkceRedirectUriStorageKey] = redirectUri;
    html.window.location.assign(flow.authenticationUri.toString());
  }

  Future<Credential?> _completeAuthorizationCodeLogin(Client client) async {
    final callbackParams = _readAuthCallbackParams();
    if (callbackParams == null || callbackParams.isEmpty) {
      return null;
    }

    if (callbackParams.containsKey('error')) {
      _lastAuthError =
          '${callbackParams['error']}: ${callbackParams['error_description'] ?? 'Authentication failed'}';
      _clearPkceSession();
      _clearAuthCallbackUrl();
      return null;
    }

    final state = html.window.sessionStorage[_pkceStateStorageKey];
    final codeVerifier = html.window.sessionStorage[_pkceVerifierStorageKey];
    final redirectUri = html.window.sessionStorage[_pkceRedirectUriStorageKey];
    if (state == null || codeVerifier == null || redirectUri == null) {
      _lastAuthError = 'Missing PKCE session state';
      _clearAuthCallbackUrl();
      return null;
    }

    final flow = Flow.authorizationCodeWithPKCE(
      client,
      state: state,
      codeVerifier: codeVerifier,
      scopes: const ['openid', 'profile', 'email', 'offline_access'],
    )..redirectUri = Uri.parse(redirectUri);

    try {
      final credential = await flow.callback(callbackParams);
      _clearPkceSession();
      _clearAuthCallbackUrl();
      return credential;
    } catch (e) {
      _lastAuthError = e.toString();
      _clearPkceSession();
      _clearAuthCallbackUrl();
      return null;
    }
  }

  bool _hasAuthCallback() {
    final callbackParams = _readAuthCallbackParams();
    return callbackParams != null && callbackParams.isNotEmpty;
  }

  Map<String, String>? _readAuthCallbackParams() {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('state') ||
        uri.queryParameters.containsKey('error') ||
        uri.queryParameters.containsKey('session_state')) {
      return uri.queryParameters;
    }

    if (uri.fragment.isEmpty) return null;

    final fragment = Uri.splitQueryString(
      uri.fragment.startsWith('?') ? uri.fragment.substring(1) : uri.fragment,
    );
    if (fragment.containsKey('code') ||
        fragment.containsKey('state') ||
        fragment.containsKey('error') ||
        fragment.containsKey('session_state')) {
      return fragment.map((key, value) => MapEntry(key, value));
    }
    return null;
  }

  void _clearAuthCallbackUrl() {
    html.window.history.replaceState(null, html.document.title, redirect);
  }

  void _clearPkceSession() {
    html.window.sessionStorage.remove(_pkceStateStorageKey);
    html.window.sessionStorage.remove(_pkceVerifierStorageKey);
    html.window.sessionStorage.remove(_pkceRedirectUriStorageKey);
  }

  String _randomString(int length) {
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  // On web we simply reuse the normal login flow with “Register” link visible.
  @override
  Future<bool> register(String u, String e, String p, String c) =>
      loginOrSignup(interactive: true);

  @override
  Future<bool> refreshSession() => loginOrSignup(interactive: false);

  Future<bool> _refreshWithStoredRefreshToken(String tokenEndpoint) async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      loadFromStorage();
      if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    }

    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode != 200) {
        _lastAuthError =
            'Refresh failed (${response.statusCode}): ${response.body}';
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = body['access_token'] as String?;
      _idToken = body['id_token'] as String?;
      _refreshToken =
          (body['refresh_token'] as String?) ?? _refreshToken;

      if (_accessToken == null || _idToken == null) {
        _lastAuthError = 'Refresh response did not include tokens';
        return false;
      }

      html.window.localStorage
        ..['access_token'] = _accessToken!
        ..['id_token'] = _idToken!
        ..['refresh_token'] = _refreshToken!;

      return true;
    } catch (e) {
      _lastAuthError = e.toString();
      return false;
    }
  }

  Future<bool> _refreshStoredCredential(Client client) async {
    if (_credential == null) {
      loadFromStorage();
      final rawCredential = _storedCredentialJson;
      if (rawCredential == null || rawCredential.isEmpty) return false;

      try {
        _credential = Credential.fromJson(
          jsonDecode(rawCredential) as Map<String, dynamic>,
        );
        _bindCredentialListener(_credential!);
      } catch (e) {
        _lastAuthError = e.toString();
        _credential = null;
        _storedCredentialJson = null;
        html.window.localStorage.remove(_credentialStorageKey);
        return false;
      }
    }

    try {
      final token = await _credential!.getTokenResponse(true);
      await _persistCredential(_credential!, token);
      return true;
    } catch (e) {
      _lastAuthError = e.toString();
      return false;
    }
  }

  Future<void> _persistCredential(
    Credential credential,
    TokenResponse token,
  ) async {
    _credential = credential;
    _bindCredentialListener(credential);

    _accessToken = token.accessToken;
    _idToken = token.idToken.toCompactSerialization();
    _storedCredentialJson = jsonEncode(credential.toJson());
    final credentialJson = jsonDecode(_storedCredentialJson!) as Map<String, dynamic>;
    _refreshToken =
        token.refreshToken ?? _findRefreshToken(credentialJson) ?? _refreshToken;

    html.window.localStorage
      ..['access_token'] = _accessToken!
      ..['id_token'] = _idToken!
      ..[_credentialStorageKey] = _storedCredentialJson!;

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      html.window.localStorage['refresh_token'] = _refreshToken!;
    }
  }

  void _bindCredentialListener(Credential credential) {
    _tokenChangedSubscription?.cancel();
    _tokenChangedSubscription = credential.onTokenChanged.listen((token) {
      _accessToken = token.accessToken;
      _idToken = token.idToken.toCompactSerialization();
      _storedCredentialJson = jsonEncode(credential.toJson());
      final credentialJson =
          jsonDecode(_storedCredentialJson!) as Map<String, dynamic>;
      _refreshToken =
          token.refreshToken ?? _findRefreshToken(credentialJson) ?? _refreshToken;
      html.window.localStorage
        ..['access_token'] = _accessToken!
        ..['id_token'] = _idToken!
        ..[_credentialStorageKey] = _storedCredentialJson!;

      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        html.window.localStorage['refresh_token'] = _refreshToken!;
      }
    });
  }

  String? _findRefreshToken(Map<String, dynamic> json) {
    const keys = ['refresh_token', 'refreshToken'];

    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _findRefreshToken(value);
        if (nested != null) return nested;
      }
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = _findRefreshToken(item);
            if (nested != null) return nested;
          }
        }
      }
    }

    return null;
  }

  bool _hasValidAccessToken() {
    loadFromStorage();
    final token = _accessToken;
    if (token == null || token.isEmpty) return false;
    return !_isAlmostExpired(token);
  }

  bool _isAlmostExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final expUtc = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return expUtc.isBefore(DateTime.now().add(const Duration(minutes: 1)));
    } catch (_) {
      return true;
    }
  }

  // --------------------------------------------------------------------------
  // **NEW** – unified token-getter used by the provider & API services
  // --------------------------------------------------------------------------
  @override
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) {
      loadFromStorage();
      if (_accessToken == null) return null;
    }

    if (_isAlmostExpired(_accessToken!)) {
      final ok = await loginOrSignup(interactive: false);
      if (!ok) return null;
    }

    return _accessToken;
  }

  @override
  Future<void> expireSession() async {
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _storedCredentialJson = null;
    _credential = null;
    await _tokenChangedSubscription?.cancel();
    _tokenChangedSubscription = null;
    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('id_token');
    html.window.localStorage.remove('refresh_token');
    html.window.localStorage.remove(_credentialStorageKey);
    _clearPkceSession();
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------
  @override
  Future<void> logout({String? postLogoutRedirectPath}) async {
    final idTokenHint = _idToken;
    final current = Uri.parse(html.window.location.href).replace(fragment: '');
    final redirectUri = Uri.parse(postLogoutRedirectPath ?? '/login');
    final postLogoutRedirect = Uri(
      scheme: current.scheme,
      host: current.host,
      port: current.hasPort ? current.port : null,
      path: redirectUri.path.isEmpty ? '/login' : redirectUri.path,
      queryParameters: redirectUri.queryParameters.isEmpty
          ? null
          : redirectUri.queryParameters,
    ).toString();

    // Clear browser storage aggressively so stale auth/invite state does not survive logout.
    html.window.localStorage.clear();
    html.window.sessionStorage.clear();
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;

    // Nuke Keycloak cookies so silent renew does not auto-log-in again
    for (final name in [
      'KC_RESTART',
      'KEYCLOAK_SESSION',
      'KEYCLOAK_IDENTITY',
      'AUTH_SESSION_ID',
    ]) {
      html.document.cookie =
          '$name=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT';
    }

    // Finally redirect to the Keycloak end-session endpoint
    final issuer = await Issuer.discover(Uri.parse(issuerUrl));
    final endSession = issuer.metadata.endSessionEndpoint!;
    final uri = endSession.replace(queryParameters: {
      'id_token_hint': idTokenHint,
      'post_logout_redirect_uri': postLogoutRedirect,
      'client_id': clientId,
    });
    html.window.location.href = uri.toString();
  }
}
