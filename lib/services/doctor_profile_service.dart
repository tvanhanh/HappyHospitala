import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'config.dart';

/// HINT: Flutter Service Method for Doctor Profile Update
class DoctorProfileService {

  /// Updates the doctor's profile and submits for approval
  static Future<bool> updateAndSubmitProfile({
    required String token,
    required String bio,
    required int experienceYears,
    required List<String> certificationsUrls,
    String? avatarUrl,
  }) async {
    final url = Uri.parse('$baseUrl/doctor/profile');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bio': bio,
          'experience_years': experienceYears,
          'certifications_urls': certificationsUrls,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error submitting profile: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }
}

/// HINT: UI Snippet for "Waiting for Admin Approval" badge
class DoctorStatusBadge extends StatelessWidget {
  final String profileStatus; // 'HIDDEN', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED'

  const DoctorStatusBadge({super.key, required this.profileStatus});

  @override
  Widget build(BuildContext context) {
    if (profileStatus == 'PENDING_APPROVAL') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 16, color: Colors.orange.shade800),
            const SizedBox(width: 6),
            Text(
              'Waiting for Admin Approval',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (profileStatus == 'ACTIVE') {
      return const Chip(
        label: Text('Active'),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    return const SizedBox.shrink();
  }
}
