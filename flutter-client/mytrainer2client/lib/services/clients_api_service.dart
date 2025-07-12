// lib/services/clients_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../models/client.dart';

/// Service for CRUD operations on Trainer → Clients
class ClientsApiService {
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

  /// Decode JSON body safely.
  Future<Map<String, dynamic>> _json(http.Response r) async =>
      jsonDecode(r.body) as Map<String, dynamic>;

  // ──────────────── CRUD ───────────────────────────────────────────

  /// Page through clients.
  Future<Page<Client>> page({
    int page = 0,
    int size = 10,
    String q = '',
    String sort = 'newest',
  }) async {
    final uri = Uri.parse('$_base/trainer/clients').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'q': q,
        'sort': sort,
      },
    );

    final res     = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load clients (${res.statusCode}): ${res.body}',
      );
    }

    final data    = await _json(res);
    final items   = (data['content'] as List)
        .cast<Map<String, dynamic>>()
        .map((j) => Client.fromJson(j))
        .toList();

    return Page<Client>(
      items: items,
      page: data['number'] as int,
      totalPages: data['totalPages'] as int,
    );
  }

  /// Create a new client.
  Future<Client> create(Client c) async {
    final uri = Uri.parse('$_base/trainer/clients');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(c.toJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'Failed to create client (${res.statusCode}): ${res.body}',
      );
    }
    return Client.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Update an existing client.
  Future<Client> update(Client c) async {
    final uri = Uri.parse('$_base/trainer/clients/${c.id}');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(c.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update client (${res.statusCode}): ${res.body}',
      );
    }
    return Client.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Delete a client by ID.
  Future<void> delete(int id) async {
    final uri = Uri.parse('$_base/trainer/clients/$id');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'Failed to delete client ($id): ${res.statusCode}',
      );
    }
  }
}

/// Simple page wrapper.
class Page<T> {
  final List<T> items;
  final int page;
  final int totalPages;

  Page({
    required this.items,
    required this.page,
    required this.totalPages,
  });
}
