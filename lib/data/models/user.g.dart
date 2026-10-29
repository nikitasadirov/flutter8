// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAddress _$UserAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserAddress', json, ($checkedConvert) {
      final val = UserAddress(
        street: $checkedConvert('street', (v) => v as String?),
        suite: $checkedConvert('suite', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String?),
        zipcode: $checkedConvert('zipcode', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UserAddressToJson(UserAddress instance) =>
    <String, dynamic>{
      'street': instance.street,
      'suite': instance.suite,
      'city': instance.city,
      'zipcode': instance.zipcode,
    };

User _$UserFromJson(Map<String, dynamic> json) => $checkedCreate('User', json, (
  $checkedConvert,
) {
  final val = User(
    id: $checkedConvert('id', (v) => (v as num).toInt()),
    name: $checkedConvert('name', (v) => v as String),
    username: $checkedConvert('username', (v) => v as String),
    email: $checkedConvert('email', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String?),
    website: $checkedConvert('website', (v) => v as String?),
    address: $checkedConvert(
      'address',
      (v) => v == null ? null : UserAddress.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'website': instance.website,
  'address': instance.address,
};
