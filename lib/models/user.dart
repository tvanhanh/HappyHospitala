import 'package:flutter_application_datlichkham/models/profile.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool isDeleted;
  final Profile? profile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.isDeleted,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      profile:
          json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}
