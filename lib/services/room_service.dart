import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class RoomService {
  // Hàm dùng chung để lấy header chứa Token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. GỌI API THÊM HOẶC CẬP NHẬT PHÒNG
  static Future<String?> saveRoom({
    String? id,
    required String roomNumber,
    required int floor,
    required String status,
    required String specialtyId,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = jsonEncode({
        'roomNumber': roomNumber,
        'floor': floor,
        'status': status,
        'specialtyId': specialtyId,
      });

      http.Response res;
      if (id == null) {
        // Nếu không có id -> Thêm mới (POST)
        res = await http.post(
          Uri.parse('$baseUrl/api/rooms'),
          headers: headers,
          body: bodyData,
        );
      } else {
        // Nếu có id -> Cập nhật (PUT)
        res = await http.put(
          Uri.parse('$baseUrl/api/rooms/$id'),
          headers: headers,
          body: bodyData,
        );
      }

      if (res.statusCode == 201 || res.statusCode == 200) {
        return null; // Null nghĩa là thành công, không có lỗi
      }
      return 'Lỗi server: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  // 2. GỌI API XÓA PHÒNG
  static Future<String?> deleteRoom(String id) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/rooms/$id'),
        headers: headers,
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return null;
      }
      return 'Lỗi xóa phòng: ${res.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }
}
