import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiClinicService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Get all services
  static Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/api/services'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        print("Lỗi tải danh sách dịch vụ: ${res.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng getServices: $e");
      return [];
    }
  }

  // 2. Add service
  static Future<String?> addService({
    required String name,
    required String description,
    required String duration,
    required double price,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/api/services'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'duration': duration,
          'price': price,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return null; // success
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Lỗi server: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 3. Update service
  static Future<String?> updateService({
    required String id,
    required String name,
    required String description,
    required String duration,
    required double price,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse('$baseUrl/api/services/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'duration': duration,
          'price': price,
        }),
      );

      if (res.statusCode == 200) {
        return null; // success
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Lỗi server: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 4. Delete service
  static Future<String?> deleteService(String id) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/services/$id'),
        headers: headers,
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return null; // success
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Lỗi server: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }
}
