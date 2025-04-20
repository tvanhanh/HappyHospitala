import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class ApiService {
  static Future<String?> registerUser(String name, String email,
      String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
       
      }),
    );

    if (res.statusCode == 201) {
      return null; // Thành công
    } else {
      final data = jsonDecode(res.body);
      return data['message'] ?? "Đăng ký thất bại";
    }
  }

  static Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        'token': data['token'],
        'role': data['user']['role'],
      };
    } else {
      final data = jsonDecode(res.body);
      return {
        'error': data['message'] ?? 'Đăng nhập thất bại',
      };
    }
  }
}
