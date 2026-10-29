import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(checked: true)
class UserAddress {
  const UserAddress({this.street, this.suite, this.city, this.zipcode});

  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;

  factory UserAddress.fromJson(Map<String, dynamic> json) =>
      _$UserAddressFromJson(json);

  Map<String, dynamic> toJson() => _$UserAddressToJson(this);
}

@JsonSerializable(checked: true)
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.website,
    this.address,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? website;
  final UserAddress? address;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
