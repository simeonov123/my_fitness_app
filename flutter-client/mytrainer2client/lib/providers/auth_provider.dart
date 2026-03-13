// lib/providers/auth_provider.dart

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../services/active_workout_service.dart';
import '../services/pending_client_invite_service.dart';

/// A [ChangeNotifier] that wraps our singleton [AuthService].
///
/// Exposes the current authentication state, login/logout flows,
/// and a way to retrieve a fresh access token.
class AuthProvider extends ChangeNotifier {
  /// Underlying singleton that manages tokens and Keycloak interactions.
  final AuthService _auth = AuthService()..loadFromStorage();

  /// Whether we currently have a non-null access token.
  bool get isAuthenticated => _auth.accessToken != null;

  /// The raw (possibly expired) access token string.
  String? get token => _auth.accessToken;

  String? get role {
    final raw = _auth.accessToken;
    if (raw == null || raw.isEmpty) return null;

    try {
      final parts = raw.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
      final realmAccess = payload['realm_access'] as Map<String, dynamic>?;
      final roles = (realmAccess?['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().toUpperCase())
          .toList();

      if (roles.contains('TRAINER')) return 'TRAINER';
      if (roles.contains('CLIENT')) return 'CLIENT';
      return null;
    } catch (_) {
      return null;
    }
  }

  bool get isTrainer => role == 'TRAINER';
  bool get isClient => role == 'CLIENT';

  /// A future that yields a valid (and auto-refreshed if needed) access token.
  ///
  /// Returns `null` if we have no token or refresh failed.
  Future<String?> getValidToken() => _auth.getValidAccessToken();

  /// Starts the interactive (or silent) login/registration flow.
  ///
  /// If [interactive] is `false`, attempts a silent refresh using a stored
  /// refresh token; returns `false` immediately if no refresh token is present.
  ///
  /// Returns `true` on success, `false` on error or user cancellation.
  Future<bool> loginOrSignup({bool interactive = true}) async {
    final ok = await _auth.loginOrSignup(interactive: interactive);
    if (ok) notifyListeners();
    return ok;
  }

  /// Shortcut for registration (Keycloak shows a “Register” link).
  ///
  /// Delegates to [loginOrSignup] with `interactive: true`.
  Future<bool> register(String u, String e, String p, String c) async {
    final ok = await _auth.register(u, e, p, c);
    if (ok) notifyListeners();
    return ok;
  }

  /// Logs out the user both locally (clearing tokens) and at Keycloak.
  ///
  /// After calling, [isAuthenticated] will become `false`. Fires [notifyListeners].
  Future<void> logout({
    bool clearPendingInvite = true,
    String? postLogoutRedirectPath,
  }) async {
    await ActiveWorkoutService().clearAll();
    if (clearPendingInvite) {
      await PendingClientInviteService().clear();
    }
    await _auth.logout(postLogoutRedirectPath: postLogoutRedirectPath);
    notifyListeners();
  }
}
