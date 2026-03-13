import 'package:flutter/material.dart';

import '../models/social_post.dart';
import '../services/social_feed_service.dart';

class SocialFeedProvider extends ChangeNotifier {
  final SocialFeedService _service = SocialFeedService();

  bool _loaded = false;
  String? _scopeKey;
  List<SocialPost> _posts = [];

  List<SocialPost> get posts => List.unmodifiable(_posts);

  Future<void> ensureLoaded() async {
    final scopeKey = await _service.currentScopeKey();
    if (_loaded && _scopeKey == scopeKey) return;

    _posts = await _service.loadPosts();
    _loaded = true;
    _scopeKey = scopeKey;
    notifyListeners();
  }

  Future<void> addPost(SocialPost post) async {
    await ensureLoaded();
    _posts = [post, ..._posts.where((item) => item.id != post.id)];
    await _service.savePosts(_posts);
    notifyListeners();
  }
}
