import 'dart:convert';

/// Mirrors the UserProfile response DTO from Spring Boot.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final String role;
  final bool profileComplete;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePictureUrl,
    required this.role,
    required this.profileComplete,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:                json['id'] as String,
        name:              json['name'] as String,
        email:             json['email'] as String,
        phoneNumber:       json['phoneNumber'] as String?,
        profilePictureUrl: json['profilePictureUrl'] as String?,
        role:              json['role'] as String,
        profileComplete:   json['profileComplete'] as bool,
        createdAt:         json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id':                id,
        'name':              name,
        'email':             email,
        'phoneNumber':       phoneNumber,
        'profilePictureUrl': profilePictureUrl,
        'role':              role,
        'profileComplete':   profileComplete,
        'createdAt':         createdAt,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  bool get isInstaller => role == 'INSTALLER';

  UserModel copyWith({String? name, String? phoneNumber, bool? profileComplete}) =>
      UserModel(
        id:                id,
        name:              name ?? this.name,
        email:             email,
        phoneNumber:       phoneNumber ?? this.phoneNumber,
        profilePictureUrl: profilePictureUrl,
        role:              role,
        profileComplete:   profileComplete ?? this.profileComplete,
        createdAt:         createdAt,
      );
}

/// Shape of the /login and /register response data field.
/// Single token — no refresh token needed.
class AuthResponseModel {
  final String accessToken;
  final UserModel user;

  const AuthResponseModel({required this.accessToken, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['accessToken'] as String,
        user:        UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
