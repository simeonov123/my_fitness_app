// lib/widgets/nutrition_template_widget.dart
import 'package:flutter/material.dart';
import '../models/nutrition_plan_template.dart';

class NutritionTemplateWidget extends StatelessWidget {
  final NutritionPlanTemplate tpl;
  final VoidCallback? onTap;

  const NutritionTemplateWidget({
    super.key,
    required this.tpl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = tpl.createdAt != null
        ? tpl.createdAt!.toLocal().toString().split('.').first
        : null;
    final updatedAt = tpl.updatedAt != null
        ? tpl.updatedAt!.toLocal().toString().split('.').first
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 40),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tpl.description!,
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
