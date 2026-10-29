import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable(checked: true)
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    this.locallyCreated = false,
  });

  final int userId;
  final int id;
  final String title;
  final String body;
  @JsonKey(defaultValue: false)
  final bool locallyCreated;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@JsonSerializable(checked: true)
class CreatePostRequest {
  const CreatePostRequest({
    required this.userId,
    required this.title,
    required this.body,
  });

  final int userId;
  final String title;
  final String body;

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
