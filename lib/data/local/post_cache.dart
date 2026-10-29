import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

class PostCache {
  static const _postsKey = 'post_explorer.cached_posts.v1';

  Future<List<Post>> readPosts() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_postsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> writePosts(List<Post> posts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _postsKey,
      jsonEncode(posts.map((post) => post.toJson()).toList()),
    );
  }
}
