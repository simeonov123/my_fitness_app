import 'dart:convert';

import 'authenticated_http.dart' as http;

import '../models/workout_folder.dart';
import 'dev_endpoints.dart';

class WorkoutFoldersUnavailableException implements Exception {
  final String message;

  const WorkoutFoldersUnavailableException(this.message);

  @override
  String toString() => message;
}

class WorkoutFoldersApiService {
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

  Future<List<WorkoutFolder>> list() async {
    final uri = Uri.parse('$_base/trainer/workout-folders');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 404) {
      throw const WorkoutFoldersUnavailableException(
        'Workout folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load workout folders (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as List<dynamic>;
    return body
        .cast<Map<String, dynamic>>()
        .map(WorkoutFolder.fromJson)
        .toList();
  }

  Future<WorkoutFolder> create(WorkoutFolder folder) async {
    final uri = Uri.parse('$_base/trainer/workout-folders');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(folder.toJson()),
    );
    if (res.statusCode == 404) {
      throw const WorkoutFoldersUnavailableException(
        'Workout folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to create workout folder (${res.statusCode}): ${res.body}');
    }
    return WorkoutFolder.fromJson(jsonDecode(res.body));
  }

  Future<WorkoutFolder> update(WorkoutFolder folder) async {
    final uri = Uri.parse('$_base/trainer/workout-folders/${folder.id}');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(folder.toJson()),
    );
    if (res.statusCode == 404) {
      throw const WorkoutFoldersUnavailableException(
        'Workout folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update workout folder (${res.statusCode}): ${res.body}');
    }
    return WorkoutFolder.fromJson(jsonDecode(res.body));
  }

  Future<void> delete(int id) async {
    final uri = Uri.parse('$_base/trainer/workout-folders/$id');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode == 404) {
      throw const WorkoutFoldersUnavailableException(
        'Workout folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 204) {
      throw Exception(
          'Failed to delete workout folder ($id): ${res.statusCode}');
    }
  }
}
