// lib/services/workout_template_exercises_api_service.dart

import 'dart:convert';

import 'authenticated_http.dart' as http;
import '../models/workout_template_exercise.dart';
import 'dev_endpoints.dart';

class WorkoutTemplateExercisesApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  Future<Map<String, String>> _headers() {
    return http.authorizedHeaders(includeJsonContentType: true);
  }

  /// List all exercises for a given workout template.
  Future<List<WorkoutTemplateExercise>> list({
    required int templateId,
  }) async {
    final uri = Uri.parse(
      '$_base/trainer/workout-templates/$templateId/exercises',
    );
    final headers = await _headers();
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load exercises: ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    final list = (body is List ? body : <dynamic>[]);
    return list
        .cast<Map<String, dynamic>>()
        .map(WorkoutTemplateExercise.fromJson)
        .toList();
  }

  /// Replace all exercises for the given template with [items].
  Future<List<WorkoutTemplateExercise>> replaceAll({
    required int templateId,
    required List<WorkoutTemplateExercise> items,
  }) async {
    final uri = Uri.parse(
      '$_base/trainer/workout-templates/$templateId/exercises',
    );
    final headers = await _headers();
    final res = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to save exercises: ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    final list = (body is List ? body : <dynamic>[]);
    return list
        .cast<Map<String, dynamic>>()
        .map(WorkoutTemplateExercise.fromJson)
        .toList();
  }

  /// Delete a single exercise entry from a template.
  Future<void> deleteOne({
    required int templateId,
    required int exerciseEntryId,
  }) async {
    final uri = Uri.parse(
      '$_base/trainer/workout-templates/$templateId/exercises/$exerciseEntryId',
    );
    final headers = await _headers();
    final res = await http.delete(uri, headers: headers);
    if (res.statusCode != 204) {
      throw Exception('Failed to delete: ${res.statusCode}');
    }
  }
}
