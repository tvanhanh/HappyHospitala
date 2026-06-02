import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JwtHelper {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUserFromToken() async {
    final token = await getToken();
    if (token == null) return null;

    return JwtDecoder.decode(token);
  }

  static Future<String?> getUserId() async {
    final data = await getUserFromToken();
    return data?['_id']; // backend phải set "id"
  }

  static Future<String?> getRole() async {
    final data = await getUserFromToken();
    return data?['role'];
  }
}
