// lib/services/exercises_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import 'dev_endpoints.dart';

class ExercisesApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  final AuthService _auth = AuthService();

  /// Build headers with a valid (and auto-refreshed) Bearer token.
  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not authenticated – please log in again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// GET /trainer/exercises?q=
  Future<List<Exercise>> list({String q = ''}) async {
    final uri = Uri.parse('$_base/trainer/exercises').replace(
      queryParameters: {if (q.isNotEmpty) 'q': q},
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load exercises: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>;
    return content.cast<Map<String, dynamic>>().map(Exercise.fromJson).toList();
  }

  /// GET /trainer/exercises/common?q=
  Future<List<Exercise>> listCommon({String q = ''}) async {
    final uri = Uri.parse('$_base/trainer/exercises/common').replace(
      queryParameters: {if (q.isNotEmpty) 'q': q},
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load common exercises: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>;
    return content.cast<Map<String, dynamic>>().map(Exercise.fromJson).toList();
  }

  Future<Exercise> create({
    required String name,
    String? description,
    required String defaultSetType,
    required String defaultSetParams,
    List<MuscleGroup> muscleGroups = const [],
  }) async {
    final uri = Uri.parse('$_base/trainer/exercises');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'isCustom': true,
        'defaultSetType': defaultSetType,
        'defaultSetParams': defaultSetParams,
        'muscleGroups': muscleGroups
            .map(
              (group) => {
                'id': group.id,
                'name': group.name,
                'isCustom': group.isCustom,
              },
            )
            .toList(growable: false),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create exercise: ${res.statusCode}');
    }
    return Exercise.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Exercise> update({
    required int id,
    required String name,
    String? description,
    required String defaultSetType,
    required String defaultSetParams,
    List<MuscleGroup> muscleGroups = const [],
  }) async {
    final uri = Uri.parse('$_base/trainer/exercises/$id');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'id': id,
        'name': name,
        'description': description,
        'isCustom': true,
        'defaultSetType': defaultSetType,
        'defaultSetParams': defaultSetParams,
        'muscleGroups': muscleGroups
            .map(
              (group) => {
                'id': group.id,
                'name': group.name,
                'isCustom': group.isCustom,
              },
            )
            .toList(growable: false),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update exercise: ${res.statusCode}');
    }
    return Exercise.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
