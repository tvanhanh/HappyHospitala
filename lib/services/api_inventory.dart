import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventory_model.dart';
import 'config.dart'; // Đảm bảo đã khai báo baseUrl trong này
import 'package:shared_preferences/shared_preferences.dart';

class ApiInventory {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }

  /// 🏢 1. LẤY DANH SÁCH TOÀN BỘ KHO HÀNG

  static Future<List<InventoryModel>> getInventories() async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/get_inventories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Tự động đính kèm token
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => InventoryModel.fromJson(item)).toList();
      } else {
        throw Exception('Không thể tải dữ liệu kho từ server (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<InventoryModel> getInventoryById(String id) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/get_inventoriesbyId/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Tự động đính kèm token
        },
      );

      if (response.statusCode == 200) {
        return InventoryModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Không tìm thấy dữ liệu lô hàng (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
 static Future<List<dynamic>> getMedicinesStock(List<String> medicineIds) async {
  try {
    final token = await _getToken();
    if (token == null || token.trim().isEmpty) {
      print("⚠️ Lỗi Xác Thực: Không tìm thấy Token trong thiết bị. Người dùng có thể chưa đăng nhập hoặc phiên làm việc đã hết hạn.");
      return []; // Trả về danh sách rỗng để app không bị crash sập nguồn
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/check-stock'),
      headers: {
        "Content-Type": "application/json", 
        'Authorization': 'Bearer $token', // Token chuẩn sẽ được đính vào đây
      },
      body: jsonEncode({"medicineIds": medicineIds}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result['data'] as List;
    } else {
      print("💥 Server từ chối cấp stock. Mã lỗi (Status Code): ${response.statusCode}");
    }
  } catch (e) {
    print("💥 Lỗi hệ thống khi tải tồn kho thuốc: $e");
  }
  return [];
}
}