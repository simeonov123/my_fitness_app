// lib/services/workout_templates_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../models/page_response.dart';
import '../models/workout_template.dart';

class WorkoutTemplatesApiService {
  static const _base = String.fromEnvironment(
    'API_BASE',
    defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
  );

  final AuthService _auth = AuthService();

  /// Build headers with a valid (and auto-refreshed) Bearer token.
  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not authenticated – please log in again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
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
    final uri     = Uri.parse('$_base/trainer/workout-templates');
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
    final uri     = Uri.parse('$_base/trainer/workout-templates/${t.id}');
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
    final uri     = Uri.parse('$_base/trainer/workout-templates/$id');
    final headers = await _headers();
    final res = await http.delete(uri, headers: headers);
    if (res.statusCode != 204) {
      throw Exception('Failed to delete ($id): ${res.statusCode}');
    }
  }
}
