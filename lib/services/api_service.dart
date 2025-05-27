import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Đăng ký người dùng
  static Future<String?> registerUser(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        return null; // Đăng ký thành công
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  // Đăng nhập người dùng
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,

  ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Lưu token vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('email', email);

        // Trả về thông tin token và role
        return {
          'token': token,
          'role': data['user']?['role'] ?? 'patient', // Đảm bảo role tồn tại
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'error': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // lấy thông tin tài khoản

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_accountList');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print("Chưa đăng nhập. Không có token.");
        return [];
      }
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => {
                  '_id': e['_id'] ??'',
                  'name': e['name'] ??'',
                  'email': e['email'] ??'',
                  'role': e['role'] ??'',
                  'status': e['status'] ??'',
                })
            .toList();
      } else {
        print("Lỗi khi lấy danh sách: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }

  // thay đổi role
  static Future<bool> changeUserRole(String id, String newRole) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_changeUserRole/$id');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': newRole}), // Gửi role mới lên
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi khi đổi vai trò: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return false;
    }
  }
   static Future<bool> changePassWord(String id, String newPassword) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api-changePassWord/$id');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': newPassword}), // Gửi role mới lên
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi khi đổi vai trò: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserInfor(String id) async {
  try {
    final url = Uri.parse('$baseUrl/auth/api_getUserInfor/$id');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print("Chưa đăng nhập. Không có token.");
      return [];
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return userData; // Trả về thông tin người dùng
      } else {
        final body = jsonDecode(response.body);
        throw Exception("Lỗi: ${body['message'] ?? 'Không xác định'}");
      }
  } catch (e) {
    print("Lỗi mạng: $e");
    return [];
  }
}

  // update User infiormation
  static Future<String> updateUserInfor(String id, String name, String phone, String address, String gender, String healthInsurance, String avatar ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_updateUserInfor/$id');
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
          "name": name,
          "phone": phone,
          "address": address,
          "gender": gender,
          "healthInsurance": healthInsurance,
          "avatar": avatar,
        }),
      );

      if (response.statusCode == 200) return "success";
      final body = jsonDecode(response.body);
      return "Lỗi: ${body['message'] ?? 'Không xác định'}";
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) {
        print("Không tìm thấy dữ liệu người dùng trong SharedPreferences.");
        return null;
      }
      final userMap = jsonDecode(userJson);
      final id = userMap['_id']?.toString();
      if (id == null) {
        print("Không tìm thấy ID người dùng trong dữ liệu.");
        return null;
      }

      final userData = await getUserInfor(id);
      if (userData.isNotEmpty) {
        return userData.first;
      }
      return null;
    } catch (e) {
      print("Lỗi khi lấy thông tin người dùng hiện tại: $e");
      return null;
    }
  }


// mở, khóa tài khoản
  static Future<bool> toggleUserStatus(String id, String newStatus) async {
    try {
      final url = Uri.parse('$baseUrl/auth/api_updateStatus/$id');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
            {'status': newStatus}), // Gửi status mới: "true" hoặc "false"
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi khi đổi trạng thái: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return false;
    }
  }

  // Lấy token từ SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      throw Exception('Không thể lấy token: $e');
    }
  }

  // Đăng xuất người dùng
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } catch (e) {
      throw Exception('Không thể đăng xuất: $e');
    }
  }

  // Gửi yêu cầu API với token (ví dụ: gọi API bảo vệ)
  static Future<Map<String, dynamic>> makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // Lấy token
      final token = await getToken();

      if (token == null) {
        return {
          'error': 'Chưa đăng nhập. Không có token.',
        };
      }

      // Tạo URL
      final url = Uri.parse('$baseUrl$endpoint');

      // Tùy chọn phương thức HTTP
      http.Response response;
      if (method.toUpperCase() == 'POST') {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method.toUpperCase() == 'GET') {
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } else {
        throw Exception('Phương thức HTTP không được hỗ trợ: $method');
      }

      // Xử lý phản hồi
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        return {
          'error': data['message'] ?? 'Yêu cầu thất bại',
        };
      }
    } catch (e) {
      return {
        'error': 'Lỗi kết nối: $e',
      };
    }
  }
}
