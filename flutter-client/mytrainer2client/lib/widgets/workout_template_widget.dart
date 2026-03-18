// lib/widgets/workout_template_widget.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../theme/app_density.dart';

class WorkoutTemplateWidget extends StatelessWidget {
  final WorkoutTemplate tpl;
  final VoidCallback? onTap;

  const WorkoutTemplateWidget({
    super.key,
    required this.tpl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = tpl.createdAt;
    final updatedAt = tpl.updatedAt;
    final exerciseCount = tpl.exercises.length;
    const accent = Color(0xFF2F80FF);
    final outline = accent.withOpacity(0.18);
    const surface = Color(0xFFF7FAFF);
    final cardRadius = AppDensity.radius(26);
    final subtitle = tpl.description?.trim().isNotEmpty == true
        ? tpl.description!.trim()
        : 'Ready to open and edit';
    final metaText = updatedAt != null
        ? 'Updated ${_formatDate(updatedAt)}'
        : createdAt != null
            ? 'Created ${_formatDate(createdAt)}'
            : 'Draft template';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Container(
        margin: AppDensity.symmetric(horizontal: 12, vertical: 6),
        padding: AppDensity.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: outline),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: AppDensity.space(20),
              offset: Offset(0, AppDensity.space(10)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppDensity.space(46),
              height: AppDensity.space(46),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: AppDensity.circular(16),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: accent,
                size: AppDensity.icon(22),
              ),
            ),
            SizedBox(width: AppDensity.space(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tpl.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF21212C),
                          ),
                        ),
                      ),
                      SizedBox(width: AppDensity.space(6)),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: AppDensity.icon(16),
                        color: Color(0xFF7A86A5),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDensity.space(4)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F7691),
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: AppDensity.space(10)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.list_alt_rounded,
                        label:
                            '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}',
                      ),
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: metaText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = _months[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, ${local.year} at ${local.hour}:$minute';
}

const List<String> _months = <String>[
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
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
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDensity.icon(14), color: const Color(0xFF2F80FF)),
          SizedBox(width: AppDensity.space(5)),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF3C4A68),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
