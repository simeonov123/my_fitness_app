// lib/screens/login_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/pending_client_invite_service.dart';
import '../widgets/landing_content.dart';
import 'package:mytrainer2client/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  /// initial silent check
  bool _checking = true;

  /// interactive auth in progress
  bool _authing = false;

  /// auth timed‑out or failed
  bool _authError = false;

  static const _timeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // first boot → finish redirect silently if there is one
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final pendingInvite =
          await PendingClientInviteService().readToken() ?? Uri.base.queryParameters['token'];
      final ok = await auth.loginOrSignup(interactive: false);
      if (ok && auth.isAuthenticated) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          pendingInvite != null && pendingInvite.isNotEmpty
              ? '/onboard/client?token=$pendingInvite'
              : auth.role == null
                  ? '/pending-approval'
                  : '/home',
        );
      } else if (pendingInvite != null && pendingInvite.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/onboard/client?token=$pendingInvite',
        );
      } else {
        if (mounted) setState(() => _checking = false);
      }
    });
  }

  /// runs the interactive flow with a timeout
  Future<void> _startAuth() async {
    setState(() {
      _authing = true;
      _authError = false;
    });

    final auth = context.read<AuthProvider>();
    final pendingInvite =
        await PendingClientInviteService().readToken() ?? Uri.base.queryParameters['token'];

    Future<bool?> task() async {
      try {
        return await auth.loginOrSignup();
      } catch (_) {
        return false;
      }
    }

    final ok = await task().timeout(_timeout, onTimeout: () => null);

    if (!mounted) return;

    if (ok == true && auth.isAuthenticated) {
      Navigator.pushReplacementNamed(
        context,
        pendingInvite != null && pendingInvite.isNotEmpty
            ? '/onboard/client?token=$pendingInvite'
            : auth.role == null
                ? '/pending-approval'
                : '/home',
      );
      return;
    }

    if (kIsWeb && ok == false) {
      // On web, interactive auth triggers a browser redirect. The auth helper can
      // briefly return before the page leaves, so keep showing the loading state
      // instead of flashing the generic error screen in that handoff window.
      return;
    }

    // either timeout (ok == null) or explicit failure (ok == false)
    setState(() {
      _authing = false;
      _authError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // 1️⃣ still boot‑checking
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2️⃣ auth splash (progress or error) ─────────────────────────────
    if (_authing || _authError) {
      return Scaffold(
        body: Center(
          child: _authing
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(loc.authenticatingLabel),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(loc.authFailedLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startAuth,
                child: Text(loc.tryAgainButton),
              ),
            ],
          ),
        ),
      );
    }

    // 3️⃣ normal landing page (no auth in progress) ──────────────────
    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/landing_page_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.2),
                child: LandingContent(
                  onSignIn: _startAuth,
                ),
              ),

              // locale toggle
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () =>
                      context.read<LocaleProvider>().toggleLocale(),
                  child: Text(
                    loc.localeToggleLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
