import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static Future<String> getRequest(String userInput) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_predict');
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
        body: jsonEncode({"request": userInput}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result['reply'] ?? "Không có phản hồi từ AI";
      }

      final body = jsonDecode(response.body);
      return "Lỗi: ${body['error'] ?? body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}
