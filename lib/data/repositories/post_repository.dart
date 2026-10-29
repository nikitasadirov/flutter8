import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

class PostRepository {
  PostRepository({required PostApi api, required PostCache cache})
    : this._(api, cache);

  PostRepository._(this._api, this._cache);

  final PostApi _api;
  final PostCache _cache;
  final Map<String, Future<List<Post>>> _inFlightPages = {};

  Future<List<Post>> getCachedPosts({int? userId}) async {
    final posts = await _cache.readPosts();
    return filterPosts(posts, userId: userId);
  }

  Future<List<Post>> getPosts({required int page, int? userId}) {
    final key = '$page:${userId ?? 'all'}';
    final pending = _inFlightPages[key];
    if (pending != null) return pending;
    final request = _fetchAndCache(page: page, userId: userId);
    _inFlightPages[key] = request;
    return request.whenComplete(() => _inFlightPages.remove(key));
  }

  Future<List<Post>> _fetchAndCache({required int page, int? userId}) async {
    try {
      final posts = await _api.getPosts(page, 10, userId: userId);
      final cached = await _cache.readPosts();
      final merged = <String, Post>{
        for (final post in cached) _cacheId(post): post,
        for (final post in posts) _cacheId(post): post,
      };
      await _cache.writePosts(merged.values.toList());
      return posts;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<Post> getPost(int id) async {
    try {
      return await _api.getPost(id);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<List<Comment>> getComments(int postId) async {
    try {
      return await _api.getComments(postId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<List<User>> getUsers() async {
    try {
      return await _api.getUsers();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<User> getUser(int id) async {
    try {
      return await _api.getUser(id);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<Post> createPost(CreatePostRequest request) async {
    try {
      final response = await _api.createPost(request);
      final localPost = Post(
        userId: response.userId,
        id: response.id,
        title: response.title,
        body: response.body,
        locallyCreated: true,
      );
      final cached = await _cache.readPosts();
      final updated = [
        localPost,
        ...cached.where(
          (item) => !(item.locallyCreated && item.id == localPost.id),
        ),
      ];
      await _cache.writePosts(updated);
      return localPost;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  List<Post> filterPosts(
    List<Post> posts, {
    int? userId,
    String query = '',
    bool ascending = true,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = posts.where((post) {
      final matchesUser = userId == null || post.userId == userId;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          post.title.toLowerCase().contains(normalizedQuery);
      return matchesUser && matchesQuery;
    }).toList();
    filtered.sort((first, second) {
      final result = first.id.compareTo(second.id);
      return ascending ? result : -result;
    });
    return filtered;
  }

  String _cacheId(Post post) =>
      '${post.locallyCreated ? 'local' : 'remote'}:${post.id}';
}
