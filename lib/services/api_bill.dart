import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_model.dart';
import 'config.dart';

class ApiBill {
  // Hàm trợ giúp lấy Token bảo mật từ SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Hàm gửi dữ liệu hóa đơn mới lên Server
  static Future<BillModel?> createBill(BillModel bill) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/create_bill"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bill.toJson()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        // Bóc tách object hóa đơn nằm trong trường 'data' trả về từ Backend TS
        return BillModel.fromJson(body['data']);
      } else {
        print("Lỗi Server: ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi API createBill: $e");
    }
    return null;
  }

  // Hàm lấy danh sách tất cả hóa đơn (đã đồng bộ với cấu trúc trả về phân trang của Backend TS)
  static Future<List<BillModel>> getAllBills({int page = 1, int limit = 20, String search = ''}) async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_bills?page=$page&limit=$limit&search=$search"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        // Đi sâu vào cấu trúc body['data']['bills'] như Backend TS đã thiết lập
        final List<dynamic> data = body['data']['bills'] ?? [];
        return data.map((item) => BillModel.fromJson(item)).toList();
      } else {
        print("Lỗi Server: ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi API getAllBills: $e");
    }
    return [];
  }

  // Hàm lấy chi tiết một hóa đơn cụ thể theo ID
  static Future<BillModel?> getBillById(String id) async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_bills/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        return BillModel.fromJson(body['data']);
      } else {
        print("Lỗi Server: ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi API getBillById: $e");
    }
    return null;
  }
}