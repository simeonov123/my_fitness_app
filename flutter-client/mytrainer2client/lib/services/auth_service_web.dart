/// Web-only AuthService implementation.
/// Uses `openid_client` + an iframe redirect for silent renew.
import 'dart:convert';
import 'dart:html' as html;

import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_browser.dart' as browser;

/// Common interface shared by all platform-specific services.
abstract class _AuthServiceBase {
  String? get accessToken;

  /// Read any tokens cached in localStorage/secure storage.
  void loadFromStorage();

  /// Start a login / signup flow.
  Future<bool> loginOrSignup({bool interactive = true});

  /// Shortcut for “Register” (falls back to normal login flow on web).
  Future<bool> register(String u, String e, String p, String c);

  /// Clear local tokens and call the Keycloak end-session endpoint.
  Future<void> logout();

  /// Return a **currently valid** JWT, silently refreshing if needed.
  Future<String?> getValidAccessToken();
}

class AuthService implements _AuthServiceBase {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // ===== Keycloak config (DEV — adjust for prod) ============================
  static const issuerUrl = 'http://localhost:8081/realms/myrealm';

  static const clientId  = 'mytrainer2client';
  static const redirect  = 'http://localhost';

  String? _accessToken;
  String? _idToken;

  @override
  String? get accessToken => _accessToken;

  // --------------------------------------------------------------------------
  // Storage helpers
  // --------------------------------------------------------------------------
  @override
  void loadFromStorage() {
    _accessToken = html.window.localStorage['access_token'];
    _idToken     = html.window.localStorage['id_token'];
  }

  // --------------------------------------------------------------------------
  // Login / signup (interactive OR silent)
  // --------------------------------------------------------------------------
  @override
  Future<bool> loginOrSignup({bool interactive = true}) async {
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
    _idToken     = token.idToken.toCompactSerialization();

    html.window.localStorage
      ..['access_token'] = _accessToken!
      ..['id_token']     = _idToken!;

    return true;
  }

  // On web we simply reuse the normal login flow with “Register” link visible.
  @override
  Future<bool> register(String u, String e, String p, String c) =>
      loginOrSignup(interactive: true);

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
    bool _isAlmostExpired(String jwt) {
      try {
        final parts   = jwt.split('.');
        if (parts.length != 3) return true;
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        ) as Map<String, dynamic>;
        final expUtc  = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        return expUtc.isBefore(DateTime.now().add(const Duration(minutes: 1)));
      } catch (_) {
        return true; // Parsing failed → treat as expired
      }
    }

    if (_isAlmostExpired(_accessToken!)) {
      final ok = await loginOrSignup(interactive: false); // silent renew
      if (!ok) return null;
    }

    return _accessToken;
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------
  @override
  Future<void> logout() async {
    // Remove from localStorage first
    html.window.localStorage
      ..remove('access_token')
      ..remove('id_token');
    _accessToken = null;

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
    final issuer      = await Issuer.discover(Uri.parse(issuerUrl));
    final endSession  = issuer.metadata.endSessionEndpoint!;
    final uri = endSession.replace(queryParameters: {
      'id_token_hint'           : _idToken,
      'post_logout_redirect_uri': redirect,
      'client_id'               : clientId,
    });
    html.window.location.href = uri.toString();
  }
}
