import 'dart:convert';

import 'authenticated_http.dart' as http;

import '../models/client_invite_validation.dart';
import 'dev_endpoints.dart';

class ClientOnboardingApiService {
  static final _baseUrl = apiBaseUrl;

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
    final uri = Uri.parse('$_baseUrl/public/client-invites/$token/accept');
    final res = await http.post(
      uri,
      headers: await http.authorizedHeaders(),
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
