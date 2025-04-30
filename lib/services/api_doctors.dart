import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class DoctorService {

   static Future<String> addDoctor (String doctorName, String email, String phone, String address, String departmentName, String specialization, String avatar   ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_addDoctor');
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
        "doctorName": doctorName,
         "email": email,
         "phone": phone,
         "address": address,
         "departmentName": departmentName,
         "specialization": specialization,
         "avatar": avatar,
        }),
      );

      if (response.statusCode == 201) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_tocdorList');

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
        return data
            .map((e) => {
                  'id': e['_id'],
                  'doctorName': e['doctorName'],
                  'email': e['email'],
                  'phone': e['phone'],
                  'address': e['address'],
                  'departmentId': e['departmentId']?.toString() ?? '',
                  'departmentName': e['departmentName'],
                  'specialization': e['specialization'],
                  'avatar': e['avatar'],
                
                })
            .toList();
      } else {
        print("Lỗi khi lấy danh sách: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }
// update 
  static Future<String> updateDoctor(String id, String name, String description) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_updateDoctor/$id');
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
      final url = Uri.parse('$baseUrl/auth/api_deleteDoctor/$id');
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

