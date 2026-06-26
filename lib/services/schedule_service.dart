import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Đảm bảo import đúng file chứa baseUrl của bạn

class ScheduleService {
  // Hàm dùng chung để lấy header chứa Token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. TẠO LỊCH TRỰC MỚI (POST /api/schedules)
  static Future<String?> assignSchedule({
    required String doctorId,
    required String roomId,
    required String date,
    required String shift,
    int timeSlotDuration = 15,
    int maxPatients = 16,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = jsonEncode({
        'doctorId': doctorId,
        'roomId': roomId,
        'date': date,
        'shift': shift,
        'timeSlotDuration': timeSlotDuration,
        'maxPatients': maxPatients,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/api/schedules'),
        headers: headers,
        body: bodyData,
      );

      // Trả về null nếu thành công, trả về câu lỗi nếu thất bại (Lớp bảo vệ 409/400)
      if (res.statusCode == 201 || res.statusCode == 200) {
        return null;
      }
      final errorData = jsonDecode(res.body);
      return errorData['message'] ?? 'Lỗi server: ${res.statusCode}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 2. LẤY LỊCH TRỰC THEO NGÀY (GET /api/schedules?date=...)
  static Future<List<dynamic>> getSchedulesByDate(String date) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/api/schedules?date=$date'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Lỗi server khi tải lịch: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  static Future<String?> deleteSchedule(String id) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/schedules/$id'),
        headers: headers,
      );
      if (res.statusCode == 200) return null;
      return jsonDecode(res.body)['message'] ?? 'Lỗi server khi xóa';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  static Future<String?> updateSchedule({
    required String id,
    required String doctorId,
    required String roomId,
    required String date,
    required String shift,
    int timeSlotDuration = 15,
    int maxPatients = 16,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = jsonEncode({
        'doctorId': doctorId,
        'roomId': roomId,
        'date': date,
        'shift': shift,
        'timeSlotDuration': timeSlotDuration,
        'maxPatients': maxPatients,
      });

      final res = await http.put(
        Uri.parse('$baseUrl/api/schedules/$id'),
        headers: headers,
        body: bodyData,
      );

      if (res.statusCode == 200) {
        return null; // Trả về null nghĩa là thành công không có lỗi
      }
      final errorData = jsonDecode(res.body);
      return errorData['message'] ??
          'Lỗi server khi cập nhật: ${res.statusCode}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 4. SAO CHÉP LỊCH TRỰC (POST /api/schedules/copy)
  // type: 'day' | 'week' | 'month'
  // fromDate & toDate: định dạng 'yyyy-MM-dd'
  // Trả về Map chứa { copied, skipped, message } nếu thành công
  // Trả về String lỗi nếu thất bại
  static Future<Map<String, dynamic>> copySchedule({
    required String type,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/api/schedules/copy'),
        headers: headers,
        body: jsonEncode({
          'type': type,
          'fromDate': fromDate,
          'toDate': toDate,
        }),
      );

      // === FIX: Kiểm tra Content-Type trước khi parse JSON ===
      // Nếu server trả về HTML (lỗi 404/500 chưa cấu hình route),
      // jsonDecode sẽ crash với lỗi "DOCTYPE"
      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message':
              'Server trả về lỗi ${res.statusCode}. Kiểm tra backend đã restart sau khi thêm route /copy chưa.',
        };
      }

      // Chỉ parse JSON khi response hợp lệ
      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Phản hồi server không hợp lệ (${res.statusCode})',
        };
      }

      if (res.statusCode == 201 || res.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Sao chép thành công!',
          'copied': body['copied'] ?? 0,
          'skipped': body['skipped'] ?? 0,
        };
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Lỗi server: ${res.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối mạng: $e',
      };
    }
  }
}
