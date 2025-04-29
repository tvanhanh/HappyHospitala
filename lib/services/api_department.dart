import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // file chứa baseUrl, ví dụ: const String baseUrl = "http://localhost:3000";
import 'package:shared_preferences/shared_preferences.dart';
class DepartmentService {
  // Thêm phòng ban
  static Future<String> addDepartment(String name, String description) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_addDepartment');
      final prefs = await SharedPreferences.getInstance();
       final token = prefs.getString('token');
       if (token == null) {
        return "Chưa đăng nhập. Không có token.";
      }
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",},
        body: jsonEncode({
          "departmentName": name,
          "description": description,
        }),
      );

      if (response.statusCode == 201) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  // Hiển thị danh sách phòng ban
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_departmentList');

      final prefs = await SharedPreferences.getInstance();
       final token = prefs.getString('token');
       if (token == null) {
        print("Chưa đăng nhập. Không có token.");
        return [];
      }
      final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
    );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => {
          'id': e['_id'],
          'departmentName': e['departmentName'],
          'description': e['description'],
        }).toList();
      } else {
        print("Lỗi khi lấy danh sách: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  // Sửa phòng ban
  static Future<String> updateDepartment(String id, String name, String description) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_updatDepartment/$id');
       final prefs = await SharedPreferences.getInstance();
       final token = prefs.getString('token');
       if (token == null) {
        return "Chưa đăng nhập. Không có token.";
      }
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
           "Authorization": "Bearer $token",
          },
        body: jsonEncode({
          "departmentName": name,
          "description": description,
        }),
      );

      if (response.statusCode == 200) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  // Xoá phòng ban
  static Future<String> deleteDepartment(String id) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_deleteDepartment/$id');
      final prefs = await SharedPreferences.getInstance();
       final token = prefs.getString('token');
       if (token == null) {
        return "Chưa đăng nhập. Không có token.";
      }
      final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
    );

      if (response.statusCode == 200) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
