// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Post', json, ($checkedConvert) {
      final val = Post(
        userId: $checkedConvert('userId', (v) => (v as num).toInt()),
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        locallyCreated: $checkedConvert(
          'locallyCreated',
          (v) => v as bool? ?? false,
        ),
      );
      return val;
    });

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'userId': instance.userId,
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'locallyCreated': instance.locallyCreated,
};

CreatePostRequest _$CreatePostRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreatePostRequest', json, ($checkedConvert) {
      final val = CreatePostRequest(
        userId: $checkedConvert('userId', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CreatePostRequestToJson(CreatePostRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'title': instance.title,
      'body': instance.body,
    };
