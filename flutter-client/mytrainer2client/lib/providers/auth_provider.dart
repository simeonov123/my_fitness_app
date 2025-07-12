// lib/providers/auth_provider.dart

import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';

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
  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }
}
