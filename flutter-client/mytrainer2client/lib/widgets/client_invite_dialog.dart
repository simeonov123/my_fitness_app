import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Future<void> _copyInvite(ClientInvite invite) async {
    await Clipboard.setData(ClipboardData(text: invite.inviteUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _invites.isNotEmpty ? _invites.first : null;

    return AlertDialog(
      title: Text('Invite ${widget.client.fullName}'),
      content: SizedBox(
        width: 440,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest == null
                        ? 'No onboarding link generated yet.'
                        : 'Latest invite status: ${latest.status}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (latest?.inviteUrl.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      latest!.inviteUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _invites
                            .map(
                              (invite) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(invite.status),
                                subtitle: Text(
                                  invite.expiresAt != null
                                      ? 'Expires ${invite.expiresAt!.toLocal()}'
                                      : 'No expiry',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Copy link',
                                      onPressed: invite.inviteUrl.isEmpty
                                          ? null
                                          : () => _copyInvite(invite),
                                      icon: const Icon(Icons.copy_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Regenerate',
                                      onPressed: _submitting
                                          ? null
                                          : () => _regenerateInvite(invite),
                                      icon: const Icon(Icons.refresh_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Revoke',
                                      onPressed: _submitting || !invite.isPending
                                          ? null
                                          : () => _revokeInvite(invite),
                                      icon: const Icon(Icons.block_outlined),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _loading || _submitting ? null : _load,
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _loading || _submitting ? null : _createInvite,
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(latest == null ? 'Create invite' : 'New invite'),
        ),
      ],
    );
  }
}
