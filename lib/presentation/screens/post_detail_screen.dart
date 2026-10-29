import 'package:flutter/material.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    required this.repository,
    required this.initialPost,
    super.key,
  });

  final PostRepository repository;
  final Post initialPost;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post = widget.initialPost;
  List<Comment> _comments = [];
  User? _author;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.initialPost.locallyCreated) {
        User? author;
        try {
          author = await widget.repository.getUser(widget.initialPost.userId);
        } catch (_) {}
        if (!mounted) return;
        setState(() => _author = author);
      } else {
        final details = await Future.wait<Object>([
          widget.repository.getPost(widget.initialPost.id),
          widget.repository.getComments(widget.initialPost.id),
          widget.repository.getUser(widget.initialPost.userId),
        ]);
        if (!mounted) return;
        setState(() {
          _post = details[0] as Post;
          _comments = details[1] as List<Comment>;
          _author = details[2] as User;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.from(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Пост и комментарии')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _loadDetails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE9ECF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _author?.name ?? 'Автор ${_post.userId}',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: const Color(0xFF4355DB)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _post.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _post.body,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.6),
                    ),
                    if (_author != null) ...[
                      const Divider(height: 28),
                      Text('${_author!.email} · ${_author!.website ?? ''}'),
                      if (_author!.address?.city case final city?) Text(city),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Комментарии',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final comment in _comments)
                Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          comment.email,
                          style: const TextStyle(color: Color(0xFF68728B)),
                        ),
                        const SizedBox(height: 10),
                        Text(comment.body),
                      ],
                    ),
                  ),
                ),
              if (_comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Комментариев нет.'),
                ),
            ],
          ),
  );
}
