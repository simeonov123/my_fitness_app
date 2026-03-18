import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_folder.dart';
import 'auth_service.dart';
import 'dev_endpoints.dart';

class ClientFoldersUnavailableException implements Exception {
  final String message;

  const ClientFoldersUnavailableException(this.message);

  @override
  String toString() => message;
}

class ClientFoldersApiService {
  static final _base =
      const String.fromEnvironment('API_BASE', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE')
          : apiBaseUrl;

  final AuthService _auth = AuthService();

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

  Future<List<ClientFolder>> list() async {
    final uri = Uri.parse('$_base/trainer/client-folders');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 404) {
      throw const ClientFoldersUnavailableException(
        'Client folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load client folders (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as List<dynamic>;
    return body
        .cast<Map<String, dynamic>>()
        .map(ClientFolder.fromJson)
        .toList();
  }

  Future<ClientFolder> create(ClientFolder folder) async {
    final uri = Uri.parse('$_base/trainer/client-folders');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(folder.toJson()),
    );
    if (res.statusCode == 404) {
      throw const ClientFoldersUnavailableException(
        'Client folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to create client folder (${res.statusCode}): ${res.body}');
    }
    return ClientFolder.fromJson(jsonDecode(res.body));
  }

  Future<ClientFolder> update(ClientFolder folder) async {
    final uri = Uri.parse('$_base/trainer/client-folders/${folder.id}');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(folder.toJson()),
    );
    if (res.statusCode == 404) {
      throw const ClientFoldersUnavailableException(
        'Client folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update client folder (${res.statusCode}): ${res.body}');
    }
    return ClientFolder.fromJson(jsonDecode(res.body));
  }

  Future<void> delete(int id) async {
    final uri = Uri.parse('$_base/trainer/client-folders/$id');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode == 404) {
      throw const ClientFoldersUnavailableException(
        'Client folders are not available on this backend yet.',
      );
    }
    if (res.statusCode != 204) {
      throw Exception(
          'Failed to delete client folder ($id): ${res.statusCode}');
    }
  }
}
