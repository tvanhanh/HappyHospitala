import 'package:flutter_application_datlichkham/models/doctor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorService {
  static Future<String> addDoctor(
      String doctorName,
      String email,
      String phone,
      String address,
      String departmentName,
      String specialization,
      String avatar) async {
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
          "Authorization": "Bearer $token",
        },
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

  // static Future<List<Map<String, dynamic>>> getDoctors() async {
  //   try {
  //     final url = Uri.parse('$baseUrl/api_doctorList');

  //     final response = await http.get(url);

  //     final body = jsonDecode(response.body);

  //     final List data = body['data'];

  //     return List<Map<String, dynamic>>.from(data);
  //   } catch (e) {
  //     print("Lỗi mạng: $e");
  //     return [];
  //   }
  // }

  static Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final url = Uri.parse('$baseUrl/doctors/api_doctorList');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final List data = body is List ? body : body['data'] ?? [];

        return data.map<Map<String, dynamic>>((e) {
          return {
            '_id': e['_id'] ?? '',
            'name': e['name'] ?? e['doctorName'] ?? '',
            'email': e['email'] ?? '',
            'profile': e['profile'] ?? {},
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

// update
  static Future<String> updateDoctor(
      String id, String name, String description) async {
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

  static Future<void> updateDoctorInfo(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("$baseUrl/doctors/$doctorId/profile");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Update doctor failed: ${response.body}");
    }
  }

  // // Xoá phòng ban
  // static Future<String> deleteDepartment(String id) async {
  //   try {
  //     final url = Uri.parse('$baseUrl/auth/api_deleteDoctor/$id');
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');
  //     if (token == null) {
  //       return "Chưa đăng nhập. Không có token.";
  //     }
  //     final response = await http.delete(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );

  //     if (response.statusCode == 200) return "success";
  //     final body = jsonDecode(response.body);
  //     return "Lỗi: ${body['message'] ?? 'Không xác định'}";
  //   } catch (e) {
  //     return "Lỗi kết nối: $e";
  //   }
  static Future<List<Doctor>> getFeaturedDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/doctors/featured'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print(res.body);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data.map<Doctor>((e) => Doctor.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    try {
      final url = Uri.parse("$baseUrl/doctors/$doctorId/api_doctor_detail");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        return body['data'] as Map<String, dynamic>; // ✔ doctor object
      }

      print("Lỗi lấy doctor: ${response.body}");
      return null;
    } catch (e) {
      print("Lỗi mạng: $e");
      return null;
    }
  }
}
