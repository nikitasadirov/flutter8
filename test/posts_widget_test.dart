import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/comment.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/models/user.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/main.dart';

class _MockPostApi extends Mock implements PostApi {}

const _users = [
  User(id: 1, name: 'Anna Author', username: 'anna', email: 'anna@test.dev'),
  User(id: 2, name: 'Boris Writer', username: 'boris', email: 'boris@test.dev'),
];

const _posts = [
  Post(userId: 1, id: 1, title: 'Flutter basics', body: 'First body text'),
  Post(userId: 2, id: 2, title: 'Dart async guide', body: 'Second body text'),
  Post(userId: 1, id: 3, title: 'Testing widgets', body: 'Third body text'),
];

void main() {
  late _MockPostApi api;

  setUpAll(() {
    registerFallbackValue(
      const CreatePostRequest(userId: 1, title: 'title', body: 'body'),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _MockPostApi();
    when(() => api.getUsers()).thenAnswer((_) async => _users);
    when(() => api.getPosts(1, 10, userId: null))
        .thenAnswer((_) async => _posts);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = PostRepository(api: api, cache: PostCache());
    await tester.pumpWidget(PostExplorerApp(repository: repository));
    await tester.pumpAndSettle();
  }

  group('Главный экран (PostsScreen)', () {
    testWidgets('показывает заголовок, элементы интерфейса и список постов',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Post Explorer'), findsOneWidget);
      expect(find.text('Читайте и находите интересное'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Поиск по заголовку'), findsOneWidget);
      expect(find.text('Новый пост'), findsOneWidget);
      expect(find.byTooltip('Создать пост'), findsOneWidget);
      expect(find.byTooltip('Сбросить фильтры'), findsOneWidget);

      expect(find.text('Flutter basics'), findsOneWidget);
      expect(find.text('Dart async guide'), findsOneWidget);
      expect(find.text('Testing widgets'), findsOneWidget);
      expect(find.text('Anna Author'), findsWidgets);
      expect(find.text('Поиск среди загруженных 3 постов'), findsOneWidget);
    });

    testWidgets('поиск фильтрует список, а сброс возвращает все посты',
        (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextField), 'dart');
      await tester.pump();

      expect(find.text('Dart async guide'), findsOneWidget);
      expect(find.text('Flutter basics'), findsNothing);
      expect(find.text('Testing widgets'), findsNothing);

      await tester.enterText(find.byType(TextField), 'такого нет');
      await tester.pump();
      expect(find.text('Ничего не найдено'), findsOneWidget);

      await tester.tap(find.byTooltip('Сбросить фильтры'));
      await tester.pumpAndSettle();

      expect(find.text('Ничего не найдено'), findsNothing);
      expect(find.text('Flutter basics'), findsOneWidget);
      expect(find.text('Dart async guide'), findsOneWidget);
      expect(find.text('Testing widgets'), findsOneWidget);
    });

    testWidgets('кнопка сортировки меняет порядок и подсказку',
        (tester) async {
      await pumpApp(tester);

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      expect(top('Flutter basics'), lessThan(top('Testing widgets')));

      await tester.tap(find.byTooltip('Сначала новые ID'));
      await tester.pump();

      expect(top('Testing widgets'), lessThan(top('Flutter basics')));
      expect(find.byTooltip('Сначала старые ID'), findsOneWidget);
    });

    testWidgets('при ошибке сервера показывает сообщение и кнопку «Повторить»',
        (tester) async {
      final request = RequestOptions(path: '/posts');
      when(() => api.getPosts(1, 10, userId: null)).thenThrow(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: request, statusCode: 503),
        ),
      );

      await pumpApp(tester);

      expect(find.text('Не удалось загрузить посты'), findsOneWidget);
      expect(find.textContaining('503'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);

      // После нажатия «Повторить» сервер отвечает успешно.
      when(() => api.getPosts(1, 10, userId: null))
          .thenAnswer((_) async => _posts);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить посты'), findsNothing);
      expect(find.text('Flutter basics'), findsOneWidget);
    });
  });

  group('Переход между экранами', () {
    testWidgets('нажатие на карточку открывает экран деталей и комментарии',
        (tester) async {
      when(() => api.getPost(1)).thenAnswer((_) async => _posts.first);
      when(() => api.getComments(1)).thenAnswer(
        (_) async => const [
          Comment(
            postId: 1,
            id: 1,
            name: 'Great read',
            email: 'fan@test.dev',
            body: 'Nice comment body',
          ),
        ],
      );
      when(() => api.getUser(1)).thenAnswer((_) async => _users.first);

      await pumpApp(tester);
      await tester.tap(find.text('Flutter basics'));
      await tester.pumpAndSettle();

      expect(find.text('Пост и комментарии'), findsOneWidget);
      expect(find.text('Комментарии'), findsOneWidget);
      expect(find.text('Great read'), findsOneWidget);
      expect(find.text('Nice comment body'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Пост и комментарии'), findsNothing);
      expect(find.text('Читайте и находите интересное'), findsOneWidget);
    });
  });

  group('Экран создания поста (CreatePostScreen)', () {
    Future<void> openCreateScreen(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Новый пост'));
      await tester.pumpAndSettle();
    }

    Finder submitButton() => find.descendant(
      of: find.byType(Form),
      matching: find.text('Создать пост'),
    );

    testWidgets('форма отображает поля и кнопку отправки', (tester) async {
      await openCreateScreen(tester);

      expect(find.text('Новый материал'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Заголовок'), findsWidgets);
      expect(find.text('Текст поста'), findsWidgets);
      expect(submitButton(), findsOneWidget);
    });

    testWidgets('некорректные данные: пустые и слишком короткие поля',
        (tester) async {
      await openCreateScreen(tester);

      // Пустая форма.
      await tester.tap(submitButton());
      await tester.pump();
      expect(find.text('Введите не менее 5 символов'), findsOneWidget);
      expect(find.text('Введите не менее 10 символов'), findsOneWidget);

      // Только пробелы тоже считаются пустым вводом (используется trim()).
      await tester.enterText(find.byType(TextFormField).at(0), '        ');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.tap(submitButton());
      await tester.pump();
      expect(find.text('Введите не менее 5 символов'), findsOneWidget);
      expect(find.text('Введите не менее 10 символов'), findsOneWidget);

      verifyNever(() => api.createPost(any()));
    });

    testWidgets('корректные данные создают пост и возвращают на список',
        (tester) async {
      when(() => api.createPost(any())).thenAnswer(
        (_) async => const Post(
          userId: 1,
          id: 101,
          title: 'My brand new post',
          body: 'This is the body of the new post',
        ),
      );
      await openCreateScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'My brand new post',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'This is the body of the new post',
      );
      await tester.tap(submitButton());
      await tester.pumpAndSettle();

      verify(() => api.createPost(any())).called(1);
      expect(find.text('Новый материал'), findsNothing);
      expect(find.text('My brand new post'), findsOneWidget);
      expect(find.text('локально'), findsOneWidget);
      expect(
        find.text('Пост создан тестовым API и сохранён локально.'),
        findsOneWidget,
      );
    });
  });
}
