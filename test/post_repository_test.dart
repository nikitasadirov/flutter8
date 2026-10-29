import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';

class _MockPostApi extends Mock implements PostApi {}

void main() {
  late _MockPostApi api;
  late PostCache cache;
  late PostRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _MockPostApi();
    cache = PostCache();
    repository = PostRepository(api: api, cache: cache);
  });

  test('Post deserializes JSON fields', () {
    final post = Post.fromJson({
      'userId': 3,
      'id': 12,
      'title': 'Hello world',
      'body': 'Post contents',
    });

    expect(post.userId, 3);
    expect(post.id, 12);
    expect(post.title, 'Hello world');
    expect(post.locallyCreated, isFalse);
  });

  test('Post serializes back to JSON', () {
    const post = Post(
      userId: 2,
      id: 8,
      title: 'A title',
      body: 'A body',
      locallyCreated: true,
    );

    expect(post.toJson(), {
      'userId': 2,
      'id': 8,
      'title': 'A title',
      'body': 'A body',
      'locallyCreated': true,
    });
  });

  test('Post rejects malformed required JSON fields safely', () {
    expect(
      () =>
          Post.fromJson({'userId': 'wrong', 'title': 'Title', 'body': 'Body'}),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('repository returns posts and updates local cache', () async {
    const posts = [Post(userId: 1, id: 1, title: 'First', body: 'Body')];
    when(() => api.getPosts(1, 10, userId: null))
        .thenAnswer((_) async => posts);

    final result = await repository.getPosts(page: 1);

    expect(result, posts);
    expect(
      (await cache.readPosts()).map((post) => post.toJson()).toList(),
      posts.map((post) => post.toJson()).toList(),
    );
  });

  test(
    'repository maps HTTP server failures into a user-facing error',
    () async {
      final request = RequestOptions(path: '/posts');
      final error = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 503),
        type: DioExceptionType.badResponse,
      );
      when(() => api.getPosts(1, 10, userId: null)).thenThrow(error);

      await expectLater(
        repository.getPosts(page: 1),
        throwsA(
          isA<AppException>()
              .having((value) => value.kind, 'kind', AppErrorKind.server)
              .having((value) => value.statusCode, 'statusCode', 503),
        ),
      );
    },
  );

  test('filter searches title and filters author then sorts by id', () {
    const posts = [
      Post(userId: 1, id: 3, title: 'Flutter news', body: ''),
      Post(userId: 2, id: 1, title: 'Flutter tips', body: ''),
      Post(userId: 1, id: 2, title: 'Dart news', body: ''),
    ];

    final result = repository.filterPosts(
      posts,
      userId: 1,
      query: 'NEWS',
      ascending: false,
    );

    expect(result.map((post) => post.id), [3, 2]);
  });

  test('parallel requests for one page share a single API request', () async {
    final completer = Completer<List<Post>>();
    var requestCount = 0;
    when(() => api.getPosts(1, 10, userId: null)).thenAnswer((_) {
      requestCount++;
      return completer.future;
    });

    final first = repository.getPosts(page: 1);
    final second = repository.getPosts(page: 1);
    completer.complete(const [
      Post(userId: 1, id: 1, title: 'One', body: 'Body'),
    ]);
    final results = await Future.wait([first, second]);

    expect(requestCount, 1);
    expect(results.first, results.last);
  });
}
