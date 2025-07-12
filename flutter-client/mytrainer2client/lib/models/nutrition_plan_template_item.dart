// lib/models/nutrition_plan_template_item.dart
class NutritionPlanTemplateItem {
  final int id;
  final String itemName;
  final String? details;
  final int? sequenceOrder;

  NutritionPlanTemplateItem({
    required this.id,
    required this.itemName,
    this.details,
    this.sequenceOrder,
  });

  factory NutritionPlanTemplateItem.fromJson(Map<String, dynamic> j) =>
      NutritionPlanTemplateItem(
        id:            j['id'] ?? 0,
        itemName:      j['itemName'] ?? '',
        details:       j['details'],
        sequenceOrder: j['sequenceOrder'],
      );

  Map<String, dynamic> toJson() => {
    'id'           : id,
    'itemName'     : itemName,
    'details'      : details,
    'sequenceOrder': sequenceOrder,
  };
}
