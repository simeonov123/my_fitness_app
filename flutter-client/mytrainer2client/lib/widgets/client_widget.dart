import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import '../models/client.dart';
import '../theme/app_density.dart';

class ClientWidget extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onInviteTap;

  const ClientWidget({
    super.key,
    required this.client,
    this.onTap,
    this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seed = client.id != 0 ? client.id.toString() : client.fullName;
    final createdAt = _formatStamp(client.createdAt);
    final updatedAt = _formatStamp(client.updatedAt);

    final cardRadius = AppDensity.radius(24);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Container(
        margin: AppDensity.symmetric(horizontal: 12, vertical: 6),
        padding: AppDensity.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: const Color(0xFFDCE8FF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F80FF).withOpacity(0.05),
              blurRadius: AppDensity.space(18),
              offset: Offset(0, AppDensity.space(8)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: AppDensity.circular(999),
                border: Border.all(color: const Color(0xFFD7E5FF)),
              ),
              child: ClipOval(
                child: AvatarPlus(
                  seed,
                  width: AppDensity.space(48),
                  height: AppDensity.space(48),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: AppDensity.space(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF232530),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.email != null && client.email!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppDensity.space(4)),
                      child: Text(
                        client.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F7691),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: AppDensity.space(10)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (createdAt != null)
                        _ClientMetaPill(
                          icon: Icons.calendar_today_rounded,
                          label: 'Created $createdAt',
                        ),
                      if (updatedAt != null)
                        _ClientMetaPill(
                          icon: Icons.update_rounded,
                          label: 'Updated $updatedAt',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDensity.space(8)),
            Column(
              children: [
                if (onInviteTap != null)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: AppDensity.circular(12),
                    ),
                    child: IconButton(
                      tooltip: 'Invite client to onboard',
                      onPressed: onInviteTap,
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF2F80FF),
                      ),
                    ),
                  ),
                SizedBox(height: AppDensity.space(6)),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppDensity.icon(15),
                  color: Color(0xFF8A93AA),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _formatStamp(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  final month = _clientMonths[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, ${local.hour}:$minute';
}

const List<String> _clientMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _ClientMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClientMetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDensity.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDensity.circular(999),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDensity.icon(13), color: const Color(0xFF2F80FF)),
          SizedBox(width: AppDensity.space(5)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF4D5A78),
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
