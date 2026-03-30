// lib/services/workout_templates_api_service.dart

import 'dart:convert';

import 'authenticated_http.dart' as http;
import '../models/page_response.dart';
import '../models/workout_template.dart';
import 'dev_endpoints.dart';

class WorkoutTemplatesApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  Future<Map<String, String>> _headers() {
    return http.authorizedHeaders(
      includeJsonAccept: true,
      includeJsonContentType: true,
    );
  }

  Future<PageResponse<WorkoutTemplate>> page({
    required int page,
    required int size,
    String q = '',
    String sort = 'newest',
  }) async {
    final uri = Uri.parse('$_base/trainer/workout-templates').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        if (q.isNotEmpty) 'q': q,
        'sort': sort,
      },
    );
    final headers = await _headers();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load workout templates (${res.statusCode}): ${res.body}',
      );
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    return PageResponse.fromJson(
      jsonMap,
      (m) => WorkoutTemplate.fromJson(m),
    );
  }

  Future<WorkoutTemplate> create(WorkoutTemplate t) async {
    final uri = Uri.parse('$_base/trainer/workout-templates');
    final headers = await _headers();
    final res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode != 201) {
      throw Exception(
        'Failed to create (${res.statusCode}): ${res.body}',
      );
    }
    return WorkoutTemplate.fromJson(jsonDecode(res.body));
  }

  Future<WorkoutTemplate> update(WorkoutTemplate t) async {
    final uri = Uri.parse('$_base/trainer/workout-templates/${t.id}');
    final headers = await _headers();
    final res = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update (${res.statusCode}): ${res.body}',
      );
    }
    return WorkoutTemplate.fromJson(jsonDecode(res.body));
  }

  Future<void> delete(int id) async {
    final uri = Uri.parse('$_base/trainer/workout-templates/$id');
    final headers = await _headers();
    final res = await http.delete(uri, headers: headers);
    if (res.statusCode != 204) {
      throw Exception('Failed to delete ($id): ${res.statusCode}');
    }
  }
}
