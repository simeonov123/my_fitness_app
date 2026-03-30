import 'package:flutter/foundation.dart';

import '../app_router.dart';

class AuthSessionManager extends ChangeNotifier {
  AuthSessionManager._internal();

  static final AuthSessionManager instance = AuthSessionManager._internal();

  bool _sessionExpired = false;

  bool get isSessionExpired => _sessionExpired;

  void clearExpiredState() {
    if (!_sessionExpired) return;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> markSessionExpired() async {
    if (_sessionExpired) {
      _showSessionExpiredScreen();
      return;
    }

    _sessionExpired = true;
    notifyListeners();
    _showSessionExpiredScreen();
  }

  void _showSessionExpiredScreen() {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil('/session-expired', (route) => false);
  }
}
