import 'dart:convert';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AppointmentApi {
  // ================= CREATE APPOINTMENT =================
 static Future<Map<String, dynamic>> addAppointment({
  required String doctorId,
  required String departmentId,
  String? patientName,
  String? phone,
  String? cccd,
  String? birthDate,
  String? gender,
  String? address,
  String? medicalHistory,
  String? allergies,
  String? reason,
  String? date,
  String? time,
  String? imageUrl,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      return {"success": false, "message": "Chưa đăng nhập"};
    }

    final Map<String, dynamic> body = {
      "doctor": doctorId,
      "department": departmentId,
    };

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        body[key] = value.trim();
      }
    }

    addIfNotEmpty("patientName", patientName);
    addIfNotEmpty("phone", phone);
    addIfNotEmpty("cccd", cccd);
    addIfNotEmpty("birthDate", birthDate);
    addIfNotEmpty("gender", gender);
    addIfNotEmpty("address", address);
    addIfNotEmpty("medicalHistory", medicalHistory);
    addIfNotEmpty("allergies", allergies);
    addIfNotEmpty("reason", reason);
    addIfNotEmpty("date", date);
    addIfNotEmpty("time", time);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      body["imageUrl"] = imageUrl;
    }

    final res = await http.post(
      Uri.parse("$baseUrl/appointments/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    return {
      "success": res.statusCode == 200 || res.statusCode == 201,
      "message": data["message"] ?? "",
      "data": data["data"],
    };
  } catch (e) {
    return {
      "success": false,
      "message": "Lỗi: $e",
    };
  }
}

  // ================= GET ALL (ADMIN) =================
  static Future<List<Appointment>> getAllAppointments() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/appointments/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);

    print("RAW RESPONSE = $body");

    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      print(res.body);

      return list.map((e) => Appointment.fromJson(e)).toList();
    }

    return [];
  }

  // ================= GET BY DOCTOR =================
  static Future<List<Appointment>> getByDoctor() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/appointments/doctor"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);

    print("RAW RESPONSE = $body");

    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      print(res.body);

      return list.map((e) => Appointment.fromJson(e)).toList();
    }

    return [];
  }

  static Future<List<Appointment>> getByPatient() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/appointments/patient"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);

    print("RAW RESPONSE = $body");

    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      print(res.body);

      return list.map((e) => Appointment.fromJson(e)).toList();
    }

    return [];
  }

  // ================= UPDATE STATUS =================
  static Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final token = await _getToken();

      final res = await http.patch(
        Uri.parse("$baseUrl/appointments/$id/$status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": status}),
      );

      final data = jsonDecode(res.body);
      print("UPDATE STATUS CALL");
      print("id: $id");
      print("status: $status");

      final success = res.statusCode == 200 && data["success"] == true;
      return {
        "success": success,
        "message": data["message"] ??
            (success ? "Cập nhật trạng thái thành công" : "Cập nhật thất bại"),
        "data": data["data"],
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Lỗi: $e",
      };
    }
  }

  static Future<void> cancelAppointment(String id) async {
    final token = await _getToken(); // 👈 phải await

    final res = await http.patch(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 👈 đúng
      },
      body: jsonEncode({
        "status": "cancelled",
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Huỷ lịch thất bại: ${res.body}");
      
    }
  }
  static Future<List<dynamic>> getAppointmentsByDate(String date) async {
  final token = await _getToken();

  final res = await http.get(
    Uri.parse("$baseUrl/appointments/date?date=$date"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  final data = jsonDecode(res.body);
   print("DATA FROM API: $data"); 
  if (res.statusCode == 200 && data["success"] == true) {
    return data["data"];
  }
  return [];
}

  // ================= TOKEN =================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}
