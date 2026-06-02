import 'dart:convert';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AppointmentApi {
  // ================= CREATE APPOINTMENT =================
  static Future<String> addAppointment({
    required String doctorId,
    required String patientName,
    required String phone,
    required String gender,
    required String address,
    required String medicalHistory,
    required String allergies,
    required String reason,
    required String date,
    required String time,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        return "Chưa đăng nhập";
      }

      final res = await http.post(
        Uri.parse("$baseUrl/appointments/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctor": doctorId,
          "patientName": patientName,
          "phone": phone,
          "gender": gender,
          "address": address,
          "medicalHistory": medicalHistory,
          "allergies": allergies,
          "reason": reason,
          "date": date,
          "time": time,
          "imageUrl": imageUrl ?? "",
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        return data["message"] ?? "success";
      } else {
        return data["message"] ?? "Lỗi tạo lịch hẹn";
      }
    } catch (e) {
      return "Lỗi: $e";
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
  static Future<String> updateStatus({
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
      if (res.statusCode == 200) {
        return data["message"] ?? "updated";
      } else {
        return "update failed";
      }
    } catch (e) {
      return "Lỗi: $e";
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

  // ================= TOKEN =================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}
