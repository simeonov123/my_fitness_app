import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/client.dart';
import '../models/client_invite.dart';
import '../services/client_invites_api_service.dart';

class ClientInviteDialog extends StatefulWidget {
  final Client client;

  const ClientInviteDialog({
    super.key,
    required this.client,
  });

  @override
  State<ClientInviteDialog> createState() => _ClientInviteDialogState();
}

class _ClientInviteDialogState extends State<ClientInviteDialog> {
  final ClientInvitesApiService _api = ClientInvitesApiService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<ClientInvite> _invites = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invites = await _api.list(widget.client.id);
      if (!mounted) return;
      setState(() {
        _invites = invites;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createInvite() async {
    await _runAction(() => _api.create(widget.client.id));
  }

  Future<void> _regenerateInvite(ClientInvite invite) async {
    await _runAction(() => _api.regenerate(widget.client.id, invite.id));
  }

  Future<void> _revokeInvite(ClientInvite invite) async {
    await _runAction(() => _api.revoke(widget.client.id, invite.id));
  }

  Future<void> _runAction(Future<ClientInvite> Function() action) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _copyInvite(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return 'No expiry';
    return DateFormat('d MMM yyyy • HH:mm').format(value.toLocal());
  }

  Color _statusColor(BuildContext context, ClientInvite invite) {
    if (invite.isAccepted) return const Color(0xFF0F9D58);
    if (invite.isPending) return const Color(0xFFF4B400);
    return Theme.of(context).colorScheme.outline;
  }

  IconData _statusIcon(ClientInvite invite) {
    if (invite.isAccepted) return Icons.verified_rounded;
    if (invite.isPending) return Icons.schedule_rounded;
    return Icons.block_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _invites.isNotEmpty ? _invites.first : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite ${widget.client.fullName}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                latest == null
                                    ? 'Create an onboarding invite for mobile or web.'
                                    : 'Latest invite is ${latest.status.toLowerCase()}. Share the right link for the client device.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (latest != null) ...[
                      _InviteHeroCard(
                        invite: latest,
                        statusColor: _statusColor(context, latest),
                        statusIcon: _statusIcon(latest),
                        onCopyIos: () => _copyInvite(latest.iosInviteUrl, 'iPhone invite'),
                        onCopyAndroid: () => _copyInvite(latest.androidInviteUrl, 'Android invite'),
                        onCopyWeb: () => _copyInvite(latest.webInviteUrl, 'Web invite'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading || _submitting ? null : _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _loading || _submitting ? null : _createInvite,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(latest == null ? 'Create invite' : 'New invite'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Invite history',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _invites.isEmpty
                          ? Center(
                              child: Text(
                                'No invites yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _invites.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final invite = _invites[index];
                                return _InviteHistoryCard(
                                  invite: invite,
                                  statusColor: _statusColor(context, invite),
                                  statusIcon: _statusIcon(invite),
                                  expiresLabel: _formatTime(invite.expiresAt),
                                  createdLabel: _formatTime(invite.createdAt),
                                  acceptedLabel: _formatTime(invite.acceptedAt),
                                  busy: _submitting,
                                  onCopyIos: () => _copyInvite(invite.iosInviteUrl, 'iPhone invite'),
                                  onCopyAndroid: () => _copyInvite(invite.androidInviteUrl, 'Android invite'),
                                  onCopyWeb: () => _copyInvite(invite.webInviteUrl, 'Web invite'),
                                  onRegenerate: () => _regenerateInvite(invite),
                                  onRevoke: invite.isPending ? () => _revokeInvite(invite) : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InviteHeroCard extends StatelessWidget {
  final ClientInvite invite;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onCopyIos;
  final VoidCallback onCopyAndroid;
  final VoidCallback onCopyWeb;

  const _InviteHeroCard({
    required this.invite,
    required this.statusColor,
    required this.statusIcon,
    required this.onCopyIos,
    required this.onCopyAndroid,
    required this.onCopyWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF3A506B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      invite.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.send_to_mobile_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Share onboarding link',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the link that matches the device your client will use.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickLinkButton(label: 'iPhone invite', icon: Icons.phone_iphone_rounded, onTap: onCopyIos),
              _QuickLinkButton(label: 'Android invite', icon: Icons.android_rounded, onTap: onCopyAndroid),
              _QuickLinkButton(label: 'Web invite', icon: Icons.language_rounded, onTap: onCopyWeb),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteHistoryCard extends StatelessWidget {
  final ClientInvite invite;
  final Color statusColor;
  final IconData statusIcon;
  final String expiresLabel;
  final String createdLabel;
  final String acceptedLabel;
  final bool busy;
  final VoidCallback onCopyIos;
  final VoidCallback onCopyAndroid;
  final VoidCallback onCopyWeb;
  final VoidCallback onRegenerate;
  final VoidCallback? onRevoke;

  const _InviteHistoryCard({
    required this.invite,
    required this.statusColor,
    required this.statusIcon,
    required this.expiresLabel,
    required this.createdLabel,
    required this.acceptedLabel,
    required this.busy,
    required this.onCopyIos,
    required this.onCopyAndroid,
    required this.onCopyWeb,
    required this.onRegenerate,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                invite.status,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                'Created $createdLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: 'Expires $expiresLabel'),
              if (invite.isAccepted) _MetaChip(label: 'Accepted $acceptedLabel'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(icon: Icons.phone_iphone_rounded, label: 'iPhone', onTap: onCopyIos),
              _ActionChip(icon: Icons.android_rounded, label: 'Android', onTap: onCopyAndroid),
              _ActionChip(icon: Icons.language_rounded, label: 'Web', onTap: onCopyWeb),
              _ActionChip(icon: Icons.refresh_rounded, label: 'Regenerate', onTap: busy ? null : onRegenerate),
              _ActionChip(icon: Icons.block_rounded, label: 'Revoke', onTap: busy ? null : onRevoke),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
