import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class SpecialtyService {
  // Hàm dùng chung để lấy header chứa Token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. GỌI API THÊM MỚI
  static Future<String?> addSpecialty({
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/api/specialties'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'imageUrl': imageUrl.isEmpty
              ? 'https://cdn-icons-png.flaticon.com/512/2864/2864303.png'
              : imageUrl,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return null; // Trả về null nghĩa là thành công, không có lỗi
      }
      return 'Lỗi server: ${res.body}'; // Trả về câu thông báo lỗi
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 2. GỌI API CẬP NHẬT
  static Future<String?> updateSpecialty({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse('$baseUrl/api/specialties/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
        }),
      );

      if (res.statusCode == 200) return null;
      return 'Lỗi cập nhật: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 3. GỌI API XÓA
  static Future<String?> deleteSpecialty(String id) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/specialties/$id'),
        headers: headers,
      );

      if (res.statusCode == 200 || res.statusCode == 204) return null;
      return 'Lỗi xóa: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }
}
