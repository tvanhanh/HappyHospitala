library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor.dart';
import '../services/api_doctors.dart';
import 'auth_provider.dart';

/// Provides a list of doctors filtered by room ID.
///
/// Usage: ref.watch(doctorProvider(roomId))
final doctorProvider =
    FutureProvider.family<List<Doctor>, String>((ref, roomId) async {
  try {
    final rawList = await DoctorService.getAdminActiveDoctors();
    // Filter by roomId and map to Doctor
    return rawList
        .where((map) => map['roomId_id'] == roomId)
        .map<Doctor>((map) {
      return Doctor(
        id: map['_id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        avatar: map['avatar']?.toString() ?? '',
        specialty: map['specialty']?.toString() ?? '',
        experience: map['experience_years']?.toString() ?? '0',
        price: map['consultationFee']?.toString() ?? '0',
        email: map['email']?.toString() ?? '',
        description: map['bio']?.toString() ?? '',
        specialtyId: map['specialtyId']?.toString() ?? '',
        roomId: map['roomId']?.toString(),
      );
    }).toList();
  } catch (e) {
    return [];
  }
});
final doctorSpecialtyProvider = StateProvider<String>((ref) => '');

/// Exposes all active doctors (for admin assignment matching).
final activeDoctorsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await DoctorService.getAdminActiveDoctors();
  } catch (_) {
    return [];
  }
});

/// Provides either featured doctors (if specialtyId is null) or all active doctors under a specific specialty.
final doctorsBySpecialtyProvider =
    FutureProvider.family<List<Doctor>, String?>((ref, specialtyId) async {
  ref.watch(authProvider);
  if (specialtyId == null || specialtyId.isEmpty) {
    return DoctorService.getFeaturedDoctors();
  }
  return DoctorService.getDoctorsBySpecialty(specialtyId);
});
