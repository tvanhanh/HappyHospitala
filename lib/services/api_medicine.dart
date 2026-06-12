import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_model.dart';
import 'config.dart'; // File này chứa biến baseUrl của bạn

class ApiMedicine {
  
  // Hàm bổ trợ lấy Token định danh người dùng từ bộ nhớ thiết bị
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }

  // 1. API: Gửi dữ liệu thuốc mới lên Server (POST)
  // Khớp với Backend: router.post('/create_medicine', createMedicine);
  static Future<MedicineModel?> createMedicine(MedicineModel medicine) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/create_medicine"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Gửi token để vượt qua bộ lọc Auth (nếu có)
        },
        body: jsonEncode(medicine.toJson()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Bóc tách đúng trường 'data' được định nghĩa từ Backend TypeScript: res.status(201).json({ success: true, data: savedMedicine })
        if (body['data'] != null) {
          return MedicineModel.fromJson(body['data']);
        }
      } else {
        final errorBody = jsonDecode(res.body);
        print("Lỗi Server (createMedicine): ${res.statusCode} - ${errorBody['message'] ?? ''}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API createMedicine: $e");
    }
    return null;
  }

  // 2. API: Lấy toàn bộ danh sách thuốc (GET)
  // Khớp với Backend: router.get('/get_medicines', getAllMedicines);
  static Future<List<MedicineModel>> getAllMedicines() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_medicines"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final List<dynamic> data = body['data']; // Bóc tách mảng danh sách thuốc từ trường 'data'
        return data.map((item) => MedicineModel.fromJson(item)).toList();
      } else {
        print("Lỗi Server (getAllMedicines): ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API getAllMedicines: $e");
    }
    return [];
  }

  // 3. API: Xóa thuốc theo ID (DELETE)
  // Khớp với Backend: router.delete('/delete_medicine/:id', deleteMedicine);
  static Future<bool> deleteMedicine(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/auth/delete_medicine/$id'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return true; // Xóa thành công, Backend trả về success: true
      } else {
        final errorBody = jsonDecode(res.body);
        print("Lỗi Server (deleteMedicine): ${res.statusCode} - ${errorBody['message'] ?? ''}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API deleteMedicine: $e");
    }
    return false;
  }
}