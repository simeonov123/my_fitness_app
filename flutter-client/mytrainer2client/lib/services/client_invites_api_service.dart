import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/client_invite.dart';
import 'auth_service.dart';
import 'dev_endpoints.dart';

class ClientInvitesApiService {
  static final _base = const String.fromEnvironment('API_BASE', defaultValue: '')
          .isNotEmpty
      ? const String.fromEnvironment('API_BASE')
      : (kIsWeb ? 'http://localhost:8080' : apiBaseUrl);

  final AuthService _auth = AuthService();

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

  Future<List<ClientInvite>> list(int clientId) async {
    final uri = Uri.parse('$_base/trainer/clients/$clientId/invites');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load invites (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as List<dynamic>;
    return body
        .cast<Map<String, dynamic>>()
        .map(ClientInvite.fromJson)
        .toList();
  }

  Future<ClientInvite> create(int clientId) async {
    final uri = Uri.parse('$_base/trainer/clients/$clientId/invites');
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create invite (${res.statusCode}): ${res.body}');
    }
    return ClientInvite.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ClientInvite> regenerate(int clientId, int inviteId) async {
    final uri = Uri.parse(
      '$_base/trainer/clients/$clientId/invites/$inviteId/regenerate',
    );
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to regenerate invite (${res.statusCode}): ${res.body}',
      );
    }
    return ClientInvite.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ClientInvite> revoke(int clientId, int inviteId) async {
    final uri = Uri.parse(
      '$_base/trainer/clients/$clientId/invites/$inviteId/revoke',
    );
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to revoke invite (${res.statusCode}): ${res.body}');
    }
    return ClientInvite.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
