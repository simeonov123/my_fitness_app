import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'pending_client_invite_service.dart';

class InviteLinkService {
  InviteLinkService._internal();
  static final InviteLinkService instance = InviteLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<String?> captureInitialInviteToken() async {
    final uri = await _appLinks.getInitialLink();
    return _extractInviteToken(uri);
  }

  void start(GlobalKey<NavigatorState> navigatorKey) {
    _sub ??= _appLinks.uriLinkStream.listen((uri) async {
      final token = _extractInviteToken(uri);
      if (token == null || token.isEmpty) return;

      await PendingClientInviteService().saveToken(token);

      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.pushNamedAndRemoveUntil(
        '/onboard/client?token=$token',
        (_) => false,
      );
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  String? _extractInviteToken(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme != 'mytrainer') return null;
    if (uri.host != 'invite') return null;
    if (!uri.path.startsWith('/client')) return null;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return null;
    return token;
  }
}
