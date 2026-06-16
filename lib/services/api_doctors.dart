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
      String avatar,
      [String? specialtyId,
      String? roomId]) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/api_addDoctor');
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
          "specialtyId": specialtyId,
          "roomId": roomId,
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
      final url = Uri.parse('$baseUrl/api/doctors/api_doctorList');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print("STATUS: ${response.statusCode}");
      // print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final List data = body is List ? body : body['data'] ?? [];

        return data.map<Map<String, dynamic>>((e) {
          return {
            '_id': e['_id'] ?? '',
            'name': e['fullName'] ?? '',
            'email': e['email'] ?? '',
            'profile': {},
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/pending');

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
        final List data = body is List ? body : [];
        return data.map<Map<String, dynamic>>((e) {
          return {
            '_id': e['_id'] ?? '',
            'name': e['name'] ?? e['fullName'] ?? '',
            'email': e['email'] ?? '',
            'phone': e['phone'] ?? '',
            'avatar': e['avatar'] ?? '',
            'profile_status': e['profile_status'] ?? '',
            'specialty': e['specialty'] ?? '',
            'experience_years': e['experience_years'] ?? 0,
            'bio': e['bio'] ?? '',
            'education': e['education'] ?? [],
            'certifications_urls': e['certifications_urls'] ?? [],
            'consultationFee': e['consultationFee'] ?? 0,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRejectedDoctors() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/rejected');

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
        final List data = body is List ? body : [];
        return data.map<Map<String, dynamic>>((e) {
          return {
            '_id': e['_id'] ?? '',
            'name': e['name'] ?? e['fullName'] ?? '',
            'email': e['email'] ?? '',
            'phone': e['phone'] ?? '',
            'avatar': e['avatar'] ?? '',
            'profile_status': e['profile_status'] ?? '',
            'specialty': e['specialty'] ?? '',
            'experience_years': e['experience_years'] ?? 0,
            'bio': e['bio'] ?? '',
            'education': e['education'] ?? [],
            'certifications_urls': e['certifications_urls'] ?? [],
            'consultationFee': e['consultationFee'] ?? 0,
            'rejection_reason': e['rejection_reason'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static Future<String> approveDoctor(String userId, String departmentId,
      String specialtyName, String roomId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/approve');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "userId": userId,
          "departmentId": departmentId,
          "specialty": specialtyName,
          "roomId": roomId,
        }),
      );

      if (response.statusCode == 200) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<String> rejectDoctor(String userId, [String? reason]) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/reject');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "userId": userId,
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminActiveDoctors() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/active');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((e) {
          final user = e['userId'] is Map ? e['userId'] : {};
          final dept = e['departmentId'] is Map ? e['departmentId'] : {};
          final room = e['roomId'] is Map ? e['roomId'] : {};
          return {
            '_id': user['_id'] ?? e['_id'] ?? '',
            'name':
                user['fullName'] ?? e['doctorName'] ?? e['name'] ?? 'Unknown',
            'email': user['email'] ?? e['email'] ?? '',
            'avatar': user['avatar'] ?? e['avatar'] ?? '',
            'specialty': dept['name'] ??
                e['specialty'] ??
                e['specialization'] ??
                'Chưa phân công',
            'specialtyId_id':
                dept['_id'] ?? e['departmentId'] ?? e['specialtyId'],
            'room': room['roomNumber'] ?? e['room'] ?? 'Chưa phân công',
            'roomId_id': room['_id'] ?? e['roomId'],
            'consultationFee': e['consultationFee'] ?? 0,
            'experience_years': e['experience_years'] ?? 0,
            'bio': e['bio'] ?? '',
          };
        }).toList();
      } else {
        throw Exception(
            'Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi getAdminActiveDoctors: $e');
    }
  }

  static Future<String> updateDoctorFee(String doctorId, int fee) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/doctors/$doctorId/fee');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"consultationFee": fee}),
      );

      if (response.statusCode == 200) {
        return "Cập nhật giá khám thành công";
      } else {
        final body = jsonDecode(response.body);
        return "Lỗi: ${body['message'] ?? 'Không xác định'}";
      }
    } catch (e) {
      return "Lỗi mạng: $e";
    }
  }

// update
  static Future<String> updateDoctor(
      String id, String name, String description) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/api_updateDoctor/$id');
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

    final url = Uri.parse("$baseUrl/api/doctors/$doctorId/profile");

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

  static Future<List<Doctor>> getFeaturedDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/api/doctors/featured'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    //print(res.body);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List data = body['data'] ?? [];
      return data.map<Doctor>((e) => Doctor.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    try {
      final url = Uri.parse("$baseUrl/api/doctors/$doctorId/api_doctor_detail");

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

  static Future<List<dynamic>> getDoctorsByDepartment(
    String departmentId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token");

      final url = Uri.parse(
        "$baseUrl/api/doctors/api_doctors_by_department/$departmentId",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // print("STATUS = ${response.statusCode}");
      // print("BODY = ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<List<Doctor>> getDoctorsBySpecialty(String specialtyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/specialties/$specialtyId/doctors'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<Doctor>((e) => Doctor.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching doctors by specialty: $e");
      return [];
    }
  }
}
