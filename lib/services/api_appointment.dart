import 'dart:convert';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AppointmentApi {
  static Future<List<String>> getBookedSlots(
      {required String doctorId, required String date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/appointments/booked-slots?doctorId=$doctorId&date=$date'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// [RACE CONDITION GUARD] Pre-submit slot check.
  /// Returns { available: bool, message: String }
  static Future<Map<String, dynamic>> checkSlotAvailability({
    required String doctorId,
    required String date,
    required String time,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/appointments/check-slot?doctorId=$doctorId&date=$date&time=$time'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {"available": false, "message": "Không kiểm tra được slot"};
    } catch (_) {
      // On network error, optimistically allow — backend will reject if needed
      return {"available": true, "message": "Không thể kiểm tra, tiếp tục đặt"};
    }
  }

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
    String? timeSlot,
    String? imageUrl,
    String? paymentMethod,
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
      addIfNotEmpty("timeSlot", timeSlot);
      addIfNotEmpty("paymentMethod", paymentMethod);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        body["imageUrl"] = imageUrl;
      }
      // print("===== BODY GỬI LÊN SERVER =====");
     // print(jsonEncode(body));
      final res = await http.post(
        Uri.parse("$baseUrl/api/appointments/add"),
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
        // Pass through slotConflict flag for 409 responses
        "slotConflict": data["slotConflict"] ?? false,
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
      Uri.parse("$baseUrl/api/appointments/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);



    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      //print(res.body);

      return list.map((e) => Appointment.fromJson(e)).toList();
    }

    return [];
  }

  // ================= GET BY DOCTOR =================
  static Future<List<Appointment>> getByDoctor() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/appointments/doctor"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);


    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      //print(res.body);

      return list.map((e) => Appointment.fromJson(e)).toList();
    }

    return [];
  }

  static Future<List<Appointment>> getByPatient() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/appointments/patient"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(res.body);

  

    if (res.statusCode == 200 && body["success"] == true) {
      final list = body["data"] as List;
      //print(res.body);

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
        Uri.parse("$baseUrl/api/appointments/$id/$status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": status}),
      );

      final data = jsonDecode(res.body);
      // print("UPDATE STATUS CALL");
      // print("id: $id");
      // print("status: $status");

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
      Uri.parse('$baseUrl/api/appointments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 👈 đúng
      },
      body: jsonEncode({
        "status": "cancelled",
      }),
    );

    // print("STATUS: ${res.statusCode}");
    // print("BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Huỷ lịch thất bại: ${res.body}");
    }
  }

  static Future<List<dynamic>> getAppointmentsByDate(String date) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/appointments/date?date=$date"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(res.body);
    //print("DATA FROM API: $data");
    if (res.statusCode == 200 && data["success"] == true) {
      return data["data"];
    }
    return [];
  }

  static Future<bool> checkInAppointment(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final res = await http.patch(
        Uri.parse("$baseUrl/api/appointments/$id/check-in"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);
      //print("CHECK-IN RESPONSE: $data");
      return res.statusCode == 200 && data["success"] == true;
    } catch (e) {
      print("Error in checkInAppointment: $e");
      return false;
    }
  }

  // ================= TOKEN =================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}
