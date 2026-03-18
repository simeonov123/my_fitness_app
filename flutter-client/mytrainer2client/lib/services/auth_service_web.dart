/// Web-only AuthService implementation.
/// Uses `openid_client` + an iframe redirect for silent renew.
library;

import 'dart:convert';
import 'dart:html' as html;

import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_browser.dart' as browser;

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
    final normalized = uri.replace(fragment: '');
    return normalized.toString();
  }

  String? _accessToken;
  String? _idToken;
  String? _lastAuthError;

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
  }

  Future<void> reloadFromStorage() async {
    loadFromStorage();
  }

  // --------------------------------------------------------------------------
  // Login / signup (interactive OR silent)
  // --------------------------------------------------------------------------
  @override
  Future<bool> loginOrSignup({bool interactive = true}) async {
    _lastAuthError = null;
    try {
      final issuer = await Issuer.discover(Uri.parse(issuerUrl));
      final client = Client(issuer, clientId);

      final auth = browser.Authenticator(
        client,
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
        prompt: interactive ? '' : 'none', // “none” = silent renew
      );

      final cred = await auth.credential;
      if (cred == null) {
        if (interactive) auth.authorize(); // Full redirect login
        return false;
      }

      final token = await cred.getTokenResponse();
      _accessToken = token.accessToken;
      _idToken = token.idToken.toCompactSerialization();

      html.window.localStorage
        ..['access_token'] = _accessToken!
        ..['id_token'] = _idToken!;

      return true;
    } catch (e) {
      _lastAuthError = e.toString();
      return false;
    }
  }

  // On web we simply reuse the normal login flow with “Register” link visible.
  @override
  Future<bool> register(String u, String e, String p, String c) =>
      loginOrSignup(interactive: true);

  Future<bool> refreshSession() => loginOrSignup(interactive: false);

  // --------------------------------------------------------------------------
  // **NEW** – unified token-getter used by the provider & API services
  // --------------------------------------------------------------------------
  @override
  Future<String?> getValidAccessToken() async {
    // 1️⃣  Make sure something is in memory…
    if (_accessToken == null) {
      loadFromStorage();
      if (_accessToken == null) return null;
    }

    // 2️⃣  Check the exp claim – if < 1 min from now, try a silent refresh.
    bool isAlmostExpired(String jwt) {
      try {
        final parts = jwt.split('.');
        if (parts.length != 3) return true;
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        ) as Map<String, dynamic>;
        final expUtc =
            DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        return expUtc.isBefore(DateTime.now().add(const Duration(minutes: 1)));
      } catch (_) {
        return true; // Parsing failed → treat as expired
      }
    }

    if (isAlmostExpired(_accessToken!)) {
      final ok = await loginOrSignup(interactive: false); // silent renew
      if (!ok) return null;
    }

    return _accessToken;
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
