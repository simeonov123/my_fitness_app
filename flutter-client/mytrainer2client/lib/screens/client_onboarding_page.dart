import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/client_invite_validation.dart';
import '../providers/auth_provider.dart';
import '../services/client_onboarding_api_service.dart';
import '../services/pending_client_invite_service.dart';

class ClientOnboardingPage extends StatefulWidget {
  final String? token;

  const ClientOnboardingPage({super.key, required this.token});

  @override
  State<ClientOnboardingPage> createState() => _ClientOnboardingPageState();
}

class _ClientOnboardingPageState extends State<ClientOnboardingPage>
    with WidgetsBindingObserver {
  final ClientOnboardingApiService _api = ClientOnboardingApiService();
  final PendingClientInviteService _pending = PendingClientInviteService();

  ClientInviteValidation? _validation;
  bool _loading = true;
  bool _submitting = false;
  bool _autoAcceptTried = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recoverAfterAuthReturn();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recoverAfterAuthReturn();
    }
  }

  Future<void> _load() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing invite token.';
      });
      return;
    }

    try {
      await _pending.saveToken(token);
      final validation = await _api.validate(token);
      if (!mounted) return;
      setState(() {
        _validation = validation;
        _loading = false;
        _submitting = false;
      });
      _maybeAutoAccept(validation);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  void _maybeAutoAccept(ClientInviteValidation validation) {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated && !auth.isTrainer && auth.role == null && validation.alreadyLinked) {
      Future.microtask(() {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/pending-approval',
          (_) => false,
        );
      });
      return;
    }

    if (_autoAcceptTried) return;

    final shouldAutoAccept = auth.isAuthenticated &&
        !auth.isTrainer &&
        !validation.alreadyLinked &&
        validation.valid;

    if (!shouldAutoAccept) return;

    _autoAcceptTried = true;
    Future.microtask(_accept);
  }

  Future<void> _beginAuth() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    final auth = context.read<AuthProvider>();

    setState(() => _submitting = true);
    try {
      await _pending.saveToken(token);
      final ok = await auth.loginOrSignup();
      if (!mounted) return;
      if (ok) {
        await _accept();
      } else {
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _accept() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final accepted = await _api.accept(token);
      await _pending.clear();
      if (!mounted) return;
      setState(() {
        _validation = accepted;
        _submitting = false;
      });
      if (accepted.valid || accepted.alreadyLinked) {
        final auth = context.read<AuthProvider>();
        Navigator.pushNamedAndRemoveUntil(
          context,
          auth.role == null ? '/pending-approval' : '/home',
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  Uri _mobileInviteUri(String token) {
    final isAndroidWeb = kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroidWeb) {
      return Uri.parse(
        'intent://invite/client?token=$token#Intent;scheme=mytrainer;package=com.mvfitness.mytrainer2client;end',
      );
    }
    return Uri.parse('mytrainer://invite/client?token=$token');
  }

  Future<void> _openInApp() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    final uri = _mobileInviteUri(token);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _goToPendingApproval() async {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/pending-approval',
      (_) => false,
    );
  }

  Future<void> _logoutToLogin() async {
    await _pending.clear();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  Future<void> _logoutTrainerAndReturnToInvite() async {
    final token = widget.token;
    final redirectPath =
        token == null || token.isEmpty ? '/login' : '/onboard/client?token=$token';

    setState(() => _submitting = true);
    await context.read<AuthProvider>().logout(
      clearPendingInvite: false,
      postLogoutRedirectPath: redirectPath,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  Future<void> _recoverAfterAuthReturn() async {
    final auth = context.read<AuthProvider>();
    await auth.reloadSession();
    if (!mounted) return;

    final invite = _validation;
    if (_submitting && invite != null && invite.valid && !invite.alreadyLinked) {
      setState(() => _submitting = false);
    }

    if (invite != null) {
      _maybeAutoAccept(invite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTrainer = auth.isTrainer;
    final invite = _validation;

    if (invite != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeAutoAccept(invite);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Client onboarding')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(
                    isAuthenticated: auth.isAuthenticated,
                    isTrainer: isTrainer,
                    hasApprovedRole: auth.role != null,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isAuthenticated,
    required bool isTrainer,
    required bool hasApprovedRole,
  }) {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                child: const Text('Try again'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        await _pending.clear();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      },
                child: const Text('Start over'),
              ),
            ],
          ),
        ],
      );
    }

    final invite = _validation;
    if (invite == null) {
      return const Text('Invite not found.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invite.alreadyLinked
                  ? 'Invite successful'
                  : invite.valid
                      ? 'You were invited to join MVFitness'
                      : 'Invite unavailable',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('Trainer: ${invite.trainerName}'),
            Text('Client profile: ${invite.clientName}'),
            if ((invite.clientEmail ?? '').isNotEmpty)
              Text('Email: ${invite.clientEmail}'),
            const SizedBox(height: 16),
            if (!invite.valid) ...[
              Text('Status: ${invite.status}'),
              const SizedBox(height: 12),
              const Text(
                'This invite cannot continue from this page anymore. You can return to login or use a different invite.',
              ),
            ] else if (invite.alreadyLinked) ...[
              Text(
                hasApprovedRole
                    ? 'This invite has already been linked to your account.'
                    : 'Your registration was linked successfully. Continue to the approval status page or switch to a different account.',
              ),
            ] else if (isTrainer) ...[
              const Text(
                'You are currently signed in as a trainer. Sign out first, then continue with the invited client account.',
              ),
            ] else ...[
              Text(
                isAuthenticated
                    ? 'Finish linking this account to the invited client profile.'
                    : 'Continue to Keycloak to sign in or create your client account.',
              ),
            ],
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (invite.valid && !invite.alreadyLinked)
                  SizedBox(
                    width: double.infinity,
                    child: isTrainer
                        ? OutlinedButton(
                            onPressed: _submitting ? null : _logoutTrainerAndReturnToInvite,
                            child: const Text('Sign out trainer'),
                          )
                        : ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : isAuthenticated
                                    ? _accept
                                    : _beginAuth,
                            child: Text(
                              _submitting
                                  ? 'Processing...'
                                  : isAuthenticated
                                      ? 'Accept invite'
                                      : 'Sign in / Sign up',
                            ),
                          ),
                  ),
                if (invite.alreadyLinked && !hasApprovedRole) ...[
                  FilledButton(
                    onPressed: _submitting ? null : _goToPendingApproval,
                    child: const Text('Check approval status'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _submitting ? null : _logoutToLogin,
                    child: const Text('Use different account'),
                  ),
                ],
                if (!invite.valid) ...[
                  OutlinedButton(
                    onPressed: _submitting ? null : _logoutToLogin,
                    child: const Text('Back to login'),
                  ),
                ],
                if (kIsWeb && !isTrainer && invite.valid && !invite.alreadyLinked) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _submitting ? null : _openInApp,
                    child: const Text('Open in app'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
