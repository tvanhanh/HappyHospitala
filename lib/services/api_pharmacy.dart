import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class PharmacyService {
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = Uri.parse('$baseUrl/categories');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print("Lỗi lấy danh mục: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  static Future<String?> createCategory(String categoryCode, String name, String? description) async {
    try {
      final url = Uri.parse('$baseUrl/categories');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'categoryCode': categoryCode,
          'name': name,
          'description': description ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Tạo danh mục thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  static Future<String?> updateCategory(String id, String categoryCode, String name, String? description) async {
    try {
      final url = Uri.parse('$baseUrl/categories/$id');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'categoryCode': categoryCode,
          'name': name,
          'description': description ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Cập nhật danh mục thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  static Future<String?> deleteCategory(String id) async {
    try {
      final url = Uri.parse('$baseUrl/categories/$id');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Xóa danh mục thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // ── MEDICINES CRUD ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMedicines() async {
    try {
      final url = Uri.parse('$baseUrl/medicines');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print("Lỗi lấy danh sách thuốc: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  static Future<String?> createMedicine(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/medicines');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return null;
      } else {
        final resData = jsonDecode(response.body);
        return resData['message'] ?? 'Thêm thuốc thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  static Future<String?> updateMedicine(String id, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/medicines/$id');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final resData = jsonDecode(response.body);
        return resData['message'] ?? 'Cập nhật thuốc thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  static Future<String?> deleteMedicine(String id) async {
    try {
      final url = Uri.parse('$baseUrl/medicines/$id');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final resData = jsonDecode(response.body);
        return resData['message'] ?? 'Xóa thuốc thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }
}
