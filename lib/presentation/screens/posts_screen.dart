import 'package:flutter/material.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({required this.repository, super.key});

  final PostRepository repository;

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const _pageSize = 10;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<Post> _posts = [];
  List<User> _users = [];
  int? _selectedUserId;
  int _page = 0;
  int _requestVersion = 0;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _showingCache = false;
  bool _ascending = true;
  String? _error;
  String? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers();
    _loadFirstPage();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.repository.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  Future<void> _loadFirstPage({bool refresh = false}) async {
    final version = ++_requestVersion;
    setState(() {
      _initialLoading = _posts.isEmpty && !refresh;
      _refreshing = refresh;
      _error = null;
      _loadMoreError = null;
      _hasMore = true;
      _page = 0;
    });

    try {
      final cached = await widget.repository.getCachedPosts(
        userId: _selectedUserId,
      );
      if (!mounted || version != _requestVersion) return;
      if (cached.isNotEmpty && _posts.isEmpty) {
        setState(() {
          _posts = cached;
          _showingCache = true;
        });
      }
    } catch (_) {}

    try {
      final results = await widget.repository.getPosts(
        page: 1,
        userId: _selectedUserId,
      );
      if (!mounted || version != _requestVersion) return;
      final localPosts = _posts.where((post) => post.locallyCreated);
      setState(() {
        _posts = _uniquePosts([...localPosts, ...results]);
        _page = 1;
        _hasMore = results.length == _pageSize;
        _showingCache = false;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      final message = AppException.from(error).message;
      setState(() {
        _error = message;
        _showingCache = _posts.isNotEmpty;
      });
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() {
          _initialLoading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore || _initialLoading || _refreshing) return;
    final version = _requestVersion;
    final nextPage = _page + 1;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final results = await widget.repository.getPosts(
        page: nextPage,
        userId: _selectedUserId,
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _posts = _uniquePosts([..._posts, ...results]);
        _page = nextPage;
        _hasMore = results.length == _pageSize;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() => _loadMoreError = AppException.from(error).message);
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) _loadNextPage();
  }

  Future<void> _changeUser(int? userId) async {
    if (userId == _selectedUserId) return;
    setState(() {
      _selectedUserId = userId;
      _posts = [];
      _showingCache = false;
    });
    await _loadFirstPage();
  }

  Future<void> _resetFilters() async {
    _searchController.clear();
    setState(() {
      _selectedUserId = null;
      _ascending = true;
      _posts = [];
      _showingCache = false;
    });
    await _loadFirstPage();
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(repository: widget.repository),
      ),
    );
    if (created == null || !mounted) return;
    setState(() => _posts = _uniquePosts([created, ..._posts]));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пост создан тестовым API и сохранён локально.'),
      ),
    );
  }

  List<Post> _uniquePosts(List<Post> posts) {
    final result = <String, Post>{};
    for (final post in posts) {
      result['${post.locallyCreated ? 'local' : 'remote'}:${post.id}'] = post;
    }
    return result.values.toList();
  }

  List<Post> get _visiblePosts => widget.repository.filterPosts(
    _posts,
    userId: _selectedUserId,
    query: _searchController.text,
    ascending: _ascending,
  );

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = _visiblePosts;
    final selectedUser = _users.where((user) => user.id == _selectedUserId);
    final selectedLabel = selectedUser.isEmpty
        ? 'Все авторы'
        : selectedUser.first.name;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            tooltip: 'Создать пост',
            onPressed: _openCreatePost,
            icon: const Icon(Icons.add_box_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Читайте и находите интересное',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Посты JSONPlaceholder · $selectedLabel',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF778099)),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Поиск по заголовку',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          key: ValueKey<int?>(_selectedUserId),
                          initialValue: _selectedUserId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Автор',
                            prefixIcon: Icon(Icons.person_outline),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Все авторы'),
                            ),
                            ..._users.map(
                              (user) => DropdownMenuItem<int?>(
                                value: user.id,
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeUser,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: _ascending
                            ? 'Сначала новые ID'
                            : 'Сначала старые ID',
                        onPressed: () =>
                            setState(() => _ascending = !_ascending),
                        icon: Icon(
                          _ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Сбросить фильтры',
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5, left: 4),
                      child: Text(
                        'Поиск среди загруженных ${_posts.length} постов',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: const Color(0xFF778099)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showingCache)
              _InfoBanner(
                icon: Icons.offline_pin_outlined,
                text: _error == null
                    ? 'Показаны сохранённые данные. Обновляем список…'
                    : 'Нет соединения. Показаны сохранённые данные.',
                action: _error == null ? null : _loadFirstPage,
              )
            else if (_error != null && _posts.isNotEmpty)
              _InfoBanner(
                icon: Icons.cloud_off_outlined,
                text: _error!,
                action: _loadFirstPage,
              ),
            Expanded(child: _buildList(visiblePosts)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.edit_note),
        label: const Text('Новый пост'),
      ),
    );
  }

  Widget _buildList(List<Post> visiblePosts) {
    if (_initialLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty && _error != null) {
      return _EmptyState(
        icon: Icons.wifi_off_outlined,
        title: 'Не удалось загрузить посты',
        message: _error!,
        onRetry: _loadFirstPage,
      );
    }
    if (visiblePosts.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: _posts.isEmpty ? 'Постов пока нет' : 'Ничего не найдено',
        message: _posts.isEmpty
            ? 'Потяните вниз, чтобы загрузить данные.'
            : 'Измените запрос или сбросьте фильтры.',
        onRetry: _posts.isEmpty ? _loadFirstPage : _resetFilters,
      );
    }

    final itemCount =
        visiblePosts.length + (_hasMore || _loadMoreError != null ? 1 : 0);
    return RefreshIndicator(
      onRefresh: () => _loadFirstPage(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= visiblePosts.length) {
            if (_loadMoreError != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(_loadMoreError!, textAlign: TextAlign.center),
                    TextButton.icon(
                      onPressed: _loadNextPage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = visiblePosts[index];
          return PostCard(
            post: post,
            authorName: _authorName(post.userId),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  repository: widget.repository,
                  initialPost: post,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _authorName(int id) {
    for (final user in _users) {
      if (user.id == id) return user.name;
    }
    return 'Автор $id';
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF1FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4355DB)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
        if (action != null)
          IconButton(
            onPressed: action,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF8C95AC)),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    ),
  );
}
