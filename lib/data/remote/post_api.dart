import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

part 'post_api.g.dart';

@RestApi(baseUrl: 'https://jsonplaceholder.typicode.com')
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit, {
    @Query('userId') int? userId,
  });

  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int id);

  @GET('/users')
  Future<List<User>> getUsers();

  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);

  @POST('/posts')
  Future<Post> createPost(@Body() CreatePostRequest request);
}
