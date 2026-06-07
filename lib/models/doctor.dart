/// Canonical Doctor model — aligned with the backend API `/doctors/featured` response.
///
/// The old `Doctor.fromJson` was reading flat fields (`json['avatar']`) but the
/// actual backend response nests profile data inside `json['profile']`.
/// This fix makes `getFeaturedDoctors()` work correctly.
library;

import 'specialty.dart';
import 'room.dart';

class Doctor {
  final String id;
  final String name;
  final String avatar;
  final String specialty;
  final String experience;
  final String price;
  final String email;
  final String description;
  final double rating;
  final String departmentId;
  final String? specialtyId;
  final String? roomId;
  final Specialty? specialtyDetails;
  final Room? roomDetails;

  const Doctor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.specialty,
    required this.experience,
    required this.price,
    this.email = '',
    this.description = '',
    this.rating = 4.8,
    this.departmentId = '',
    this.specialtyId,
    this.roomId,
    this.specialtyDetails,
    this.roomDetails,
  });

  /// [BUG-FIX] The backend nests avatar/specialty/experience/price inside `profile`.
  /// Old code read `json['avatar']` (flat) — this returns empty for all doctors.
  factory Doctor.fromJson(Map<String, dynamic> json) {
    final profile = (json['profile'] as Map<String, dynamic>?) ?? {};
    return Doctor(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['doctorName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: profile['avatar']?.toString() ?? json['avatar']?.toString() ?? '',
      specialty: profile['specialty']?.toString() ?? json['specialty']?.toString() ?? '',
      experience: profile['experience']?.toString() ?? json['experience']?.toString() ?? '',
      price: profile['price']?.toString() ?? json['price']?.toString() ?? '',
      description: profile['description']?.toString() ?? json['description']?.toString() ?? '',
      rating: (profile['rating'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 4.8,
      departmentId: json['departmentId']?.toString() ?? '',
      specialtyId: json['specialtyId'] is String 
          ? json['specialtyId'] 
          : (json['specialtyId'] is Map ? json['specialtyId']['_id']?.toString() : null),
      roomId: json['roomId'] is String 
          ? json['roomId'] 
          : (json['roomId'] is Map ? json['roomId']['_id']?.toString() : null),
      specialtyDetails: json['specialtyId'] is Map 
          ? Specialty.fromJson(json['specialtyId']) 
          : null,
      roomDetails: json['roomId'] is Map 
          ? Room.fromJson(json['roomId']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'profile': {
          'avatar': avatar,
          'specialty': specialty,
          'experience': experience,
          'price': price,
          'description': description,
          'rating': rating,
        },
        'departmentId': departmentId,
        'specialtyId': specialtyId ?? specialtyDetails?.id,
        'roomId': roomId ?? roomDetails?.id,
      };
}
