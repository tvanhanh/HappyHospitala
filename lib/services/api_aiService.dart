import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static Future<Map<String, dynamic>> predictDisease(
      Map<String, dynamic> patientData) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/api_predict');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        return {"error": "Chưa đăng nhập. Không có token."};
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(patientData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result;
      }

      final body = jsonDecode(response.body);
      return {
        "error": body['error'] ?? body['message'] ?? 'Lỗi không xác định'
      };
    } catch (e) {
      return {"error": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> predictSkin({
    required List<int> imageBytes,
    required String filename,
    required String age,
    required String sex,
    required String localization,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/api_predict_skin');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        return {"success": false, "message": "Chưa đăng nhập. Không có token."};
      }

      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['age'] = age
        ..fields['sex'] = sex
        ..fields['localization'] = localization
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: filename,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {"success": true, "result": result};
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body['message'] ?? body['details'] ?? 'Lỗi không xác định'
        };
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  Future<int> getAIDecision(Map<String, dynamic> state) async {
    try {
      final url = Uri.parse('$baseUrl/api/ai/predictPPO');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        return -1;
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(state),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result['decision'];
      }

      return -1;
    } catch (e) {
      return -1;
    }
  }
}