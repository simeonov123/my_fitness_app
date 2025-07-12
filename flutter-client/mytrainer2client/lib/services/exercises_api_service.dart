// lib/services/exercises_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../models/exercise.dart';

class ExercisesApiService {
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
    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>;
    return content
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
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
    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>;
    return content
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }
}
