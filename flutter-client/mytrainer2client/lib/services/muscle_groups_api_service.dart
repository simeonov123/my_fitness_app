import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/muscle_group.dart';
import '../services/auth_service.dart';
import 'dev_endpoints.dart';

class MuscleGroupsApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  final AuthService _auth = AuthService();
  static const _primaryPath = '/trainer/muscle-groups';
  static const _fallbackPath = '/trainer/exercises/muscle-groups';

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

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<http.Response> _withFallback(
    Future<http.Response> Function(Uri uri) send,
  ) async {
    final primary = await send(_uri(_primaryPath));
    if (primary.statusCode != 404) return primary;
    return send(_uri(_fallbackPath));
  }

  String _errorDetails(http.Response res) {
    final body = res.body.trim().isEmpty ? '<empty body>' : res.body;
    return '${res.statusCode} • $body';
  }

  Future<List<MuscleGroup>> list() async {
    final headers = await _headers();
    final res = await _withFallback(
      (uri) => http.get(uri, headers: headers),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load muscle groups: ${_errorDetails(res)}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MuscleGroup.fromJson)
        .toList(growable: false);
  }

  Future<MuscleGroup> create({required String name}) async {
    final headers = await _headers();
    final payload = jsonEncode({
      'name': name,
      'isCustom': true,
    });
    final res = await _withFallback(
      (uri) => http.post(
        uri,
        headers: headers,
        body: payload,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create muscle group: ${_errorDetails(res)}');
    }
    return MuscleGroup.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<MuscleGroup> update({
    required int id,
    required String name,
  }) async {
    final headers = await _headers();
    final payload = jsonEncode({
      'id': id,
      'name': name,
      'isCustom': true,
    });
    final res = await _withFallback(
      (uri) => http.put(
        Uri.parse('$uri/$id'),
        headers: headers,
        body: payload,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update muscle group: ${_errorDetails(res)}');
    }
    return MuscleGroup.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final headers = await _headers();
    final res = await _withFallback(
      (uri) => http.delete(Uri.parse('$uri/$id'), headers: headers),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete muscle group: ${_errorDetails(res)}');
    }
  }
}
