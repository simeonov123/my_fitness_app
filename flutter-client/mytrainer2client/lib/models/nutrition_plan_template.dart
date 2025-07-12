// lib/models/nutrition_plan_template.dart
import 'nutrition_plan_template_item.dart';

class NutritionPlanTemplate {
  final int id;
  final String name;
  final String? description;
  final List<NutritionPlanTemplateItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NutritionPlanTemplate({
    required this.id,
    required this.name,
    this.description,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory NutritionPlanTemplate.fromJson(Map<String, dynamic> j) =>
      NutritionPlanTemplate(
        id        : j['id'] ?? 0,
        name      : j['name'] ?? '',
        description: j['description'],
        items     : (j['items'] as List? ?? [])
            .map((e) => NutritionPlanTemplateItem.fromJson(e))
            .toList(),
        createdAt : j['createdAt'] != null ? DateTime.parse(j['createdAt']) : null,
        updatedAt : j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
    'id'         : id,
    'name'       : name,
    'description': description,
    'items'      : items.map((e) => e.toJson()).toList(),
  };
}
