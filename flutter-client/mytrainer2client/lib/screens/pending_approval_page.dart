import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/pending_client_invite_service.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  static const _phoneNumber = '+359882706700';
  Timer? _pollTimer;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshApproval();
    });
    _refreshApproval();
  }

  Future<void> _refreshApproval() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.loginOrSignup(interactive: false);
      if (!mounted) return;

      final pendingInvite = await PendingClientInviteService().readToken();
      if (!mounted) return;

      if (auth.role != null) {
        _pollTimer?.cancel();
        Navigator.pushNamedAndRemoveUntil(
          context,
          pendingInvite != null && pendingInvite.isNotEmpty
              ? '/onboard/client?token=$pendingInvite'
              : '/home',
          (_) => false,
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _callNow() async {
    final uri = Uri.parse('tel:$_phoneNumber');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration pending')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your registration was received.',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You must wait for an agent to review and confirm your registration before you can use the app.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This page refreshes automatically every 5 seconds to check whether your account has been approved.',
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      _phoneNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Call this number to speed things up.'),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _refreshing ? null : _refreshApproval,
                          child: Text(_refreshing ? 'Checking...' : 'Refresh now'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _callNow,
                          child: const Text('Call now'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _logout,
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
