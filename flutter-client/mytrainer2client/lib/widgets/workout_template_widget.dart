// lib/widgets/workout_template_widget.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';

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
    // Format creation timestamp
    final createdAt = tpl.createdAt
        ?.toLocal()
        .toString()
        .split('.')
        .first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tpl.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tpl.description != null && tpl.description!.isNotEmpty)
                    Text(
                      tpl.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (createdAt != null)
                    Text(
                      'Created: $createdAt',
                      style: Theme.of(context).textTheme.bodySmall,
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
