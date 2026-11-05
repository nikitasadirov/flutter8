import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';

class _MockPostApi extends Mock implements PostApi {}

DioException _dioError(DioExceptionType type, {int? status}) {
  final request = RequestOptions(path: '/posts');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreatePostRequest(userId: 1, title: 'title', body: 'body'),
    );
  });

  group('AppException.from (обработка ошибок)', () {
    test('таймаут Dio -> AppErrorKind.timeout', () {
      final error = AppException.from(
        _dioError(DioExceptionType.receiveTimeout),
      );
      expect(error.kind, AppErrorKind.timeout);
    });

    test('ошибка соединения -> AppErrorKind.offline', () {
      final error = AppException.from(
        _dioError(DioExceptionType.connectionError),
      );
      expect(error.kind, AppErrorKind.offline);
    });

    test('HTTP 404 -> client, HTTP 500 -> server, статус сохраняется', () {
      final client = AppException.from(
        _dioError(DioExceptionType.badResponse, status: 404),
      );
      final server = AppException.from(
        _dioError(DioExceptionType.badResponse, status: 500),
      );

      expect(client.kind, AppErrorKind.client);
      expect(client.statusCode, 404);
      expect(server.kind, AppErrorKind.server);
      expect(server.statusCode, 500);
    });

    test('FormatException -> invalidResponse, неизвестная ошибка -> unknown', () {
      expect(
        AppException.from(const FormatException('bad')).kind,
        AppErrorKind.invalidResponse,
      );
      expect(AppException.from(StateError('x')).kind, AppErrorKind.unknown);
    });

    test('уже готовый AppException возвращается без изменений', () {
      const original = AppException(AppErrorKind.server, 'msg');
      expect(identical(AppException.from(original), original), isTrue);
    });
  });

  group('PostCache (локальное хранилище)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('пустой кэш возвращает пустой список', () async {
      expect(await PostCache().readPosts(), isEmpty);
    });

    test('записанные посты читаются обратно без потерь', () async {
      final cache = PostCache();
      const posts = [
        Post(userId: 1, id: 1, title: 'One', body: 'Body 1'),
        Post(
          userId: 2,
          id: 101,
          title: 'Two',
          body: 'Body 2',
          locallyCreated: true,
        ),
      ];

      await cache.writePosts(posts);
      final restored = await cache.readPosts();

      expect(
        restored.map((post) => post.toJson()).toList(),
        posts.map((post) => post.toJson()).toList(),
      );
    });

    test('повреждённый JSON в кэше не ломает приложение', () async {
      SharedPreferences.setMockInitialValues({
        'post_explorer.cached_posts.v1': '{это не json',
      });
      expect(await PostCache().readPosts(), isEmpty);
    });
  });

  group('PostRepository (бизнес-логика)', () {
    late _MockPostApi api;
    late PostCache cache;
    late PostRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      api = _MockPostApi();
      cache = PostCache();
      repository = PostRepository(api: api, cache: cache);
    });

    test('createPost помечает пост как локальный и кладёт его в начало кэша',
        () async {
      await cache.writePosts(const [
        Post(userId: 1, id: 1, title: 'Old', body: 'Old body'),
      ]);
      when(() => api.createPost(any())).thenAnswer(
        (_) async =>
            const Post(userId: 3, id: 101, title: 'New title', body: 'Body'),
      );

      final created = await repository.createPost(
        const CreatePostRequest(userId: 3, title: 'New title', body: 'Body'),
      );
      final cached = await cache.readPosts();

      expect(created.locallyCreated, isTrue);
      expect(cached.first.id, 101);
      expect(cached.first.locallyCreated, isTrue);
      expect(cached.length, 2);
    });

    test('createPost превращает сетевую ошибку в AppException', () async {
      when(() => api.createPost(any()))
          .thenThrow(_dioError(DioExceptionType.connectionError));

      await expectLater(
        repository.createPost(
          const CreatePostRequest(userId: 1, title: 'Title', body: 'Body'),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            AppErrorKind.offline,
          ),
        ),
      );
    });

    test('getPosts объединяет новые посты с кэшем без дублей', () async {
      await cache.writePosts(const [
        Post(userId: 1, id: 1, title: 'Cached', body: 'b'),
      ]);
      when(() => api.getPosts(1, 10, userId: null)).thenAnswer(
        (_) async => const [
          Post(userId: 1, id: 1, title: 'Fresh', body: 'b'),
          Post(userId: 1, id: 2, title: 'Second', body: 'b'),
        ],
      );

      await repository.getPosts(page: 1);
      final cached = await cache.readPosts();

      expect(cached.length, 2);
      expect(cached.firstWhere((p) => p.id == 1).title, 'Fresh');
    });

    test('filterPosts: пустой результат при поиске без совпадений', () {
      const posts = [Post(userId: 1, id: 1, title: 'Flutter', body: '')];
      expect(repository.filterPosts(posts, query: 'zzz'), isEmpty);
    });

    test('filterPosts: пробелы вокруг запроса игнорируются, регистр не важен',
        () {
      const posts = [Post(userId: 1, id: 1, title: 'Flutter Tips', body: '')];
      expect(repository.filterPosts(posts, query: '  FLUTTER  '), hasLength(1));
    });

    test('filterPosts: сортировка по возрастанию и убыванию id', () {
      const posts = [
        Post(userId: 1, id: 2, title: 'b', body: ''),
        Post(userId: 1, id: 3, title: 'c', body: ''),
        Post(userId: 1, id: 1, title: 'a', body: ''),
      ];
      expect(
        repository.filterPosts(posts).map((p) => p.id),
        [1, 2, 3],
      );
      expect(
        repository.filterPosts(posts, ascending: false).map((p) => p.id),
        [3, 2, 1],
      );
    });
  });
}
