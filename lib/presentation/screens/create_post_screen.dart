import 'package:flutter/material.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({required this.repository, super.key});

  final PostRepository repository;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  List<User> _users = [];
  int? _userId;
  bool _loadingUsers = true;
  bool _submitting = false;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.repository.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _userId = users.isEmpty ? null : users.first.id;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _userError = AppException.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;
    setState(() => _submitting = true);
    try {
      final post = await widget.repository.createPost(
        CreatePostRequest(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          userId: _userId!,
        ),
      );
      if (mounted) Navigator.of(context).pop(post);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppException.from(error).message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Создать пост')),
    body: _loadingUsers
        ? const Center(child: CircularProgressIndicator())
        : _users.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_userError ?? 'Список авторов пока недоступен.'),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadingUsers = true;
                        _userError = null;
                      });
                      _loadUsers();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          )
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Новый материал',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'JSONPlaceholder принимает тестовый POST, но не хранит его постоянно.',
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Заголовок',
                    hintText: 'От 5 до 100 символов',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 5) return 'Введите не менее 5 символов';
                    if (length > 100) return 'Не более 100 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Текст поста',
                    hintText: 'От 10 до 1000 символов',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 10) return 'Введите не менее 10 символов';
                    if (length > 1000) return 'Не более 1000 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _userId,
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _users
                      .map(
                        (user) => DropdownMenuItem<int>(
                          value: user.id,
                          child: Text('${user.name} (@${user.username})'),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _userId = value),
                  validator: (value) =>
                      value == null ? 'Выберите автора' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Отправка…' : 'Создать пост'),
                ),
              ],
            ),
          ),
  );
}
