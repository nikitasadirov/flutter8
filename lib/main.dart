import 'package:flutter/material.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/posts_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = PostRepository(
    api: PostApi(DioClient.create()),
    cache: PostCache(),
  );
  runApp(PostExplorerApp(repository: repository));
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({required this.repository, super.key});

  final PostRepository repository;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1B2640);
    const accent = Color(0xFF4355DB);
    return MaterialApp(
      title: 'Post Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          primary: accent,
          surface: const Color(0xFFF8F9FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
      ),
      home: PostsScreen(repository: repository),
    );
  }
}
