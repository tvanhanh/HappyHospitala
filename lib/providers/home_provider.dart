/// Riverpod providers for the Patient Home Screen.
///
/// Exposes:
/// - [featuredDoctorsProvider] — list of featured doctors from backend API
/// - [homeSliderProvider] — dynamic slider images from backend DB
/// - [specialtiesProvider] — medical specialties grid data
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../models/doctor.dart';
import '../services/api_doctors.dart';
import '../services/config.dart';
import 'auth_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FEATURED DOCTORS PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Fetches featured doctors from the `/doctors/featured` API endpoint.
///
/// [BUG-FIX] Previously failed because [Doctor.fromJson] read flat JSON fields
/// while the backend nests them inside a `profile` sub-object.
/// This fix is in the updated [Doctor.fromJson].
///
/// This provider works even for guest users (no auth token required),
/// because the featured doctors endpoint is public.
final featuredDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  ref.watch(authProvider);
  return DoctorService.getFeaturedDoctors();
});

/// Alias using the all-doctors endpoint as fallback if /featured returns empty.
/// Falls back to [DoctorService.getDoctors] and picks first 6.
final featuredDoctorsFallbackProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final doctors = await DoctorService.getDoctors();
    return doctors.take(6).toList();
  } catch (_) {
    return [];
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// HOME SLIDER PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Represents a single promotional slider item.
class SliderItem {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isActive;

  const SliderItem({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.subtitle = '',
    this.isActive = true,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      id: json['_id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'isActive': isActive,
      };
}

/// Fetches active slider items from the backend `/sliders` API.
///
/// Falls back to a set of local asset-based defaults when the API returns empty,
/// so the home screen always shows something visually appealing.
final homeSliderProvider = FutureProvider<List<SliderItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  try {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .get(Uri.parse('$baseUrl/sliders'), headers: headers)
        .timeout(const Duration(seconds: 5));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List raw = body is List
          ? body
          : (body['data'] ?? body['sliders'] ?? []) as List;
      final items = raw
          .map((e) => SliderItem.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive && s.imageUrl.isNotEmpty)
          .toList();
      if (items.isNotEmpty) return items;
    }
  } catch (_) {
    // Network error — fall through to defaults
  }

  // Default local asset slides (always visible even without backend)
  return [
    const SliderItem(
      id: 'default1',
      imageUrl: '',
      title: 'Chăm Sóc Sức Khỏe Toàn Diện',
      subtitle: 'Đội ngũ bác sĩ chuyên nghiệp, tận tâm',
    ),
    const SliderItem(
      id: 'default2',
      imageUrl: '',
      title: 'AI Hỗ Trợ Chẩn Đoán',
      subtitle: 'Phát hiện bệnh sớm với trí tuệ nhân tạo',
    ),
    const SliderItem(
      id: 'default3',
      imageUrl: '',
      title: 'Đặt Lịch Nhanh Chóng',
      subtitle: 'Chỉ vài bước đơn giản để có lịch hẹn',
    ),
  ];
});

// ══════════════════════════════════════════════════════════════════════════════
// MEDICAL SPECIALTIES
// ══════════════════════════════════════════════════════════════════════════════

/// Static list of medical specialties for the home screen grid.
/// In a future sprint, this can be migrated to a backend API.
class Specialty {
  final String name;
  final String icon;
  final String color;

  const Specialty({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Static specialties — sourced from the ERD's department list.
const List<Specialty> kSpecialties = [
  Specialty(name: 'Nội khoa', icon: '🫀', color: 'FF5252'),
  Specialty(name: 'Ngoại khoa', icon: '🔪', color: '448AFF'),
  Specialty(name: 'Nhi khoa', icon: '👶', color: 'FF7043'),
  Specialty(name: 'Da liễu', icon: '🧴', color: 'AB47BC'),
  Specialty(name: 'Tai-Mũi-Họng', icon: '👂', color: '26A69A'),
  Specialty(name: 'Mắt', icon: '👁️', color: '29B6F6'),
  Specialty(name: 'Tim mạch', icon: '❤️', color: 'EF5350'),
  Specialty(name: 'Thần kinh', icon: '🧠', color: '7E57C2'),
  Specialty(name: 'Tiểu đường', icon: '💉', color: '66BB6A'),
  Specialty(name: 'X-quang', icon: '🩻', color: '78909C'),
];

// ══════════════════════════════════════════════════════════════════════════════
// SLIDER CRUD (for Admin Dashboard)
// ══════════════════════════════════════════════════════════════════════════════

/// Slider management service — CRUD operations for Admin.
class SliderService {
  /// Fetches all slider items (including inactive ones) — Admin only.
  static Future<List<SliderItem>> getAllSliders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse('$baseUrl/sliders/all'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List raw = body is List ? body : (body['data'] ?? []) as List;
      return raw
          .map((e) => SliderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a new slider item with image upload.
  static Future<bool> createSlider(
      XFile imageFile, String title, String subtitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 1. Upload to Cloudinary directly (like BookingScreen does)
      const cloudName = 'dwlikpvh9';
      const uploadPreset = 'asset_clinic';
      final cloudUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final cloudReq = http.MultipartRequest('POST', cloudUrl);
      cloudReq.fields['upload_preset'] = uploadPreset;
      cloudReq.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );
      final cloudRes = await cloudReq.send();
      if (cloudRes.statusCode != 200) {
        print('Cloudinary upload failed: ${cloudRes.statusCode}');
        return false;
      }
      final cloudResData = await cloudRes.stream.bytesToString();
      final cloudJson = jsonDecode(cloudResData);
      final imageUrl = cloudJson['secure_url'];

      if (imageUrl == null) return false;

      // 2. Send the URL to backend
      final response = await http.post(
        Uri.parse('$baseUrl/sliders'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'subtitle': subtitle,
          'imageUrl': imageUrl,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Exception in createSlider: $e');
      return false;
    }
  }

  /// Toggles active/inactive state of a slider.
  static Future<bool> toggleSlider(String id, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.patch(
      Uri.parse('$baseUrl/sliders/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isActive': isActive}),
    );
    return res.statusCode == 200;
  }

  /// Deletes a slider by ID.
  static Future<bool> deleteSlider(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.delete(
      Uri.parse('$baseUrl/sliders/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return res.statusCode == 200;
  }
}
