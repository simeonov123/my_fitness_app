import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _ClientOnboardingPageState extends State<ClientOnboardingPage> {
  final ClientOnboardingApiService _api = ClientOnboardingApiService();
  final PendingClientInviteService _pending = PendingClientInviteService();

  ClientInviteValidation? _validation;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTrainer = auth.isTrainer;

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
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isAuthenticated,
    required bool isTrainer,
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
              invite.valid ? 'You were invited to join MVFitness' : 'Invite unavailable',
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
            ] else if (invite.alreadyLinked) ...[
              const Text('This invite has already been used for a linked client account.'),
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
            if (invite.valid && !invite.alreadyLinked)
              SizedBox(
                width: double.infinity,
                child: isTrainer
                    ? OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                await context.read<AuthProvider>().logout();
                                if (!mounted) return;
                                setState(() {});
                              },
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
          ],
        ),
      ),
    );
  }
}
