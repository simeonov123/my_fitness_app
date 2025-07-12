// lib/providers/nutrition_templates_provider.dart
import 'package:flutter/material.dart';
import '../models/nutrition_plan_template.dart';
import '../services/nutrition_templates_api_service.dart';

class NutritionTemplatesProvider extends ChangeNotifier {
  final NutritionTemplatesApiService _api = NutritionTemplatesApiService();

  bool loading = false;
  String search = '';
  String sort = 'newest';
  int size = 10;
  int page = 0;
  int totalPages = 1;
  List<NutritionPlanTemplate> items = [];

  Future<void> load({
    required String token,
    int? toPage,
    String? newSearch,
    String? newSort,
  }) async {
    loading = true;
    if (newSearch != null) search = newSearch;
    if (newSort != null) sort = newSort;
    if (toPage != null) page = toPage;
    notifyListeners();

    final p = await _api.page(
      page: page,
      size: size,
      q: search,
      sort: sort,
    );

    items = p.items;
    page = p.page;
    totalPages = p.totalPages;
    loading = false;
    notifyListeners();
  }

  Future<void> save({
    required String token,
    required NutritionPlanTemplate t,
  }) async {
    if (t.id == 0) {
      final created = await _api.create(t);
      items.insert(0, created);
    } else {
      final updated = await _api.update(t);
      final idx = items.indexWhere((e) => e.id == t.id);
      if (idx != -1) items[idx] = updated;
    }
    notifyListeners();
  }

  Future<void> remove({
    required String token,
    required int id,
  }) async {
    await _api.delete(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
