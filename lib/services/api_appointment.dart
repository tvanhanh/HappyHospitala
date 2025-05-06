import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // file chứa BASE_URL
import 'package:shared_preferences/shared_preferences.dart';

class AddAppointments {
  static Future<String> addAppointment(
    String patientName,
    String phone,
    String reason,
    String date,
    String time,
    String departmentName,
    String doctorId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/appointments/addAppointment');

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
          "patientName": patientName,
          "phone": phone,
          "reason": reason,
          "date": date,
          "time": time,
          'departmentName': departmentName,
          'doctorId': doctorId,
        }),
      );

      if (response.statusCode == 200) {
        return "success";
      } else {
        final body = jsonDecode(response.body);
        return "Lỗi: ${body['message'] ?? 'Không xác định'}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<List<dynamic>> getMonthlyAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception("Chưa đăng nhập. Không có token.");
      }

      final url = Uri.parse('$baseUrl/appointments/monthly');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Dữ liệu thống kê lịch hẹn: $data');
        return data.cast<Map<String, dynamic>>();
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Không xác định');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
