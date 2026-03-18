import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_invite_validation.dart';
import 'auth_service.dart';
import 'dev_endpoints.dart';

class ClientOnboardingApiService {
  static final _baseUrl = apiBaseUrl;
  final AuthService _auth = AuthService();

  Future<ClientInviteValidation> validate(String token) async {
    final uri = Uri.parse('$_baseUrl/public/client-invites/$token');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
        'Validate invite failed (${res.statusCode}): ${res.body.isEmpty ? "<empty body>" : res.body}',
      );
    }
    return ClientInviteValidation.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<ClientInviteValidation> accept(String token) async {
    final accessToken = await _auth.getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Missing access token');
    }

    final uri = Uri.parse('$_baseUrl/public/client-invites/$token/accept');
    final res = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Accept invite failed (${res.statusCode}): ${res.body.isEmpty ? "<empty body>" : res.body}',
      );
    }
    return ClientInviteValidation.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
