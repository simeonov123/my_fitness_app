import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/social_post.dart';

class SocialFeedService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'social_feed_posts';

  Future<List<SocialPost>> loadPosts() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(SocialPost.fromJson)
        .toList(growable: false);
  }

  Future<void> savePosts(List<SocialPost> posts) {
    final payload = jsonEncode(posts.map((post) => post.toJson()).toList());
    return _storage.write(key: _key, value: payload);
  }
}
