import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Hoặc thư viện quản lý Token của bạn
import '../models/category_model.dart';
import 'config.dart'; 
class ApiCategoryOfMedicine {
 
    static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_category"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Gửi kèm token bảo mật
        },
      );

      final body = jsonDecode(res.body);
      print("RAW CATEGORIES RESPONSE = $body");

      // Check đúng chuẩn cấu trúc Backend trả về thành công
      if (res.statusCode == 200) {
        // Nếu Backend của bạn bọc data trong body["data"] và body["success"] == true
        if (body is Map && body["success"] == true) {
          final list = body["data"] as List;
          return list.map((e) => CategoryModel.fromJson(e)).toList();
        } 
        // Nếu Backend của bạn trả về thẳng một Array List (không bọc trong object success)
        else if (body is List) {
          return body.map((e) => CategoryModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("💥 Lỗi khi gọi API getAllCategories: $e");
    }

    return []; // Trả về mảng rỗng nếu có lỗi hoặc statusCode không chuẩn
  }

  // 2. HÀM THÊM DANH MỤC THUỐC MỚI
  // 2. HÀM THÊM DANH MỤC THUỐC MỚI (ĐÃ CẬP NHẬT THEO LOG THỰC TẾ)
  static Future<CategoryModel?> createCategory({required String categoryname, String? description}) async {
    try {
      final token = await _getToken();

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/create_category"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "categoryname": categoryname,
          "description": description ?? "",
        }),
      );
      final body = jsonDecode(res.body);
      print("RAW CREATE CATEGORY RESPONSE = $body");

      if (res.statusCode == 201 || res.statusCode == 200) {
        // Trường hợp 1: Backend trả về một List (Mảng) như log của bạn: [{_id: ..., categoryname: ...}]
        if (body is List && body.isNotEmpty) {
          return CategoryModel.fromJson(body.first as Map<String, dynamic>);
        }
        
        // Trường hợp 2: Backend trả về Object trực tiếp: {_id: ..., categoryname: ...}
        if (body is Map && body.containsKey('_id')) {
          return CategoryModel.fromJson(body as Map<String, dynamic>);
        }

        // Trường hợp 3: Backend trả về dạng bọc bởi data: {success: true, data: {...}}
        if (body is Map && body["success"] == true && body["data"] != null) {
          return CategoryModel.fromJson(body["data"]);
        }
      }
      
      // Nếu Backend trả về success: false (Ví dụ: danh mục đã tồn tại)
      if (body is Map && body["success"] == false) {
        print("Backend từ chối: ${body["message"]}");
      }

    } catch (e) {
      print("💥 Lỗi khi gọi API createCategory: $e");
    }

    return null; 
  }
}