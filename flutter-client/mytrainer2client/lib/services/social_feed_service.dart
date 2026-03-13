import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/social_post.dart';
import 'auth_service.dart';

class SocialFeedService {
  static const _storage = FlutterSecureStorage();
  static const _legacyKey = 'social_feed_posts';
  final AuthService _auth = AuthService();

  Future<String> currentScopeKey() async {
    final token = await _auth.getValidAccessToken() ?? _auth.accessToken;
    if (token == null || token.isEmpty) return _legacyKey;

    try {
      final parts = token.split('.');
      if (parts.length < 2) return _legacyKey;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final raw = (payload['sub'] as String?) ??
          (payload['preferred_username'] as String?) ??
          _legacyKey;
      final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      return '${_legacyKey}_$safe';
    } catch (_) {
      return _legacyKey;
    }
  }

  Future<List<SocialPost>> loadPosts() async {
    final key = await currentScopeKey();
    final raw = await _storage.read(key: key) ??
        (key == _legacyKey ? null : await _storage.read(key: _legacyKey));
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(SocialPost.fromJson)
        .toList(growable: false);
  }

  Future<void> savePosts(List<SocialPost> posts) async {
    final key = await currentScopeKey();
    final payload = jsonEncode(posts.map((post) => post.toJson()).toList());
    await _storage.write(key: key, value: payload);
  }
}
