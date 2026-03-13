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
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return null;

    if (uri.scheme == 'mytrainer') {
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      final combined = '$host$path';

      if (host == 'invite' && path.startsWith('/client')) {
        return token;
      }
      if (host == 'client') {
        return token;
      }
      if (combined.contains('invite/client') || combined.contains('client')) {
        return token;
      }

      // Android browsers and intent dispatch can normalize custom schemes differently.
      // If it is our custom scheme and it carries a token, treat it as an invite.
      return token;
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.toLowerCase().startsWith('/onboard/client')) {
      return token;
    }

    return null;
  }
}
