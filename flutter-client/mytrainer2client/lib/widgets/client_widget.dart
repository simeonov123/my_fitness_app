// File: lib/widgets/client_widget.dart

import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import '../models/client.dart';

class ClientWidget extends StatefulWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientWidget({
    super.key,
    required this.client,
    this.onTap,
  });

  @override
  State<ClientWidget> createState() => _ClientWidgetState();
}

class _ClientWidgetState extends State<ClientWidget> {
  @override
  Widget build(BuildContext context) {
    final c = widget.client;

    // A *stable* seed → avatar colour won’t jump between rebuilds.
    final seed = c.id != 0 ? c.id.toString() : c.fullName;

    // Format timestamps for display (fall back to raw string if needed)
    final createdAt = c.createdAt?.toLocal().toString().split('.').first;
    final updatedAt = c.updatedAt?.toLocal().toString().split('.').first;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: AvatarPlus(
                seed,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (c.email != null && c.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        c.email!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Created: $createdAt',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Updated: $updatedAt',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
