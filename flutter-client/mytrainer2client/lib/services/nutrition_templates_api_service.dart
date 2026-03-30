// lib/services/nutrition_templates_api_service.dart

import 'dart:convert';

import 'authenticated_http.dart' as http;
import '../models/nutrition_plan_template.dart';
import 'dev_endpoints.dart';

/// Service for CRUD operations on Trainer → Nutrition Templates
class NutritionTemplatesApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  Future<Map<String, String>> _headers() {
    return http.authorizedHeaders(includeJsonContentType: true);
  }

  /// Decode JSON body safely.
  Future<Map<String, dynamic>> _json(http.Response r) async =>
      jsonDecode(r.body) as Map<String, dynamic>;

  // ──────────────── CRUD ───────────────────────────────────────────

  /// Page through nutrition plan templates.
  Future<Page<NutritionPlanTemplate>> page({
    int page = 0,
    int size = 10,
    String q = '',
    String sort = 'newest',
  }) async {
    final uri = Uri.parse('$_base/trainer/nutrition-templates').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'q': q,
        'sort': sort,
      },
    );

    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load nutrition templates (${res.statusCode}): ${res.body}',
      );
    }
    final data = await _json(res);
    final items = (data['content'] as List)
        .cast<Map<String, dynamic>>()
        .map((j) => NutritionPlanTemplate.fromJson(j))
        .toList();

    return Page<NutritionPlanTemplate>(
      items: items,
      page: data['number'] as int,
      totalPages: data['totalPages'] as int,
    );
  }

  /// Create a new nutrition plan template.
  Future<NutritionPlanTemplate> create(
    NutritionPlanTemplate t,
  ) async {
    final uri = Uri.parse('$_base/trainer/nutrition-templates');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'Failed to create nutrition template (${res.statusCode}): ${res.body}',
      );
    }
    return NutritionPlanTemplate.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Update an existing nutrition plan template.
  Future<NutritionPlanTemplate> update(
    NutritionPlanTemplate t,
  ) async {
    final uri = Uri.parse('$_base/trainer/nutrition-templates/${t.id}');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update nutrition template (${res.statusCode}): ${res.body}',
      );
    }
    return NutritionPlanTemplate.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Delete a nutrition plan template by ID.
  Future<void> delete(
    int id,
  ) async {
    final uri = Uri.parse('$_base/trainer/nutrition-templates/$id');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'Failed to delete nutrition template ($id): ${res.statusCode}',
      );
    }
  }
}

/// Simple page wrapper identical to other services
class Page<T> {
  final List<T> items;
  final int page;
  final int totalPages;

  Page({required this.items, required this.page, required this.totalPages});
}
