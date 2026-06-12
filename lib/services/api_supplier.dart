import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier_model.dart';
import 'config.dart';
 import 'package:shared_preferences/shared_preferences.dart'; // Mở ra nếu bạn dùng để lấy token

class ApiSupplier {

   static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }


  // Hàm gửi dữ liệu nhà cung cấp mới lên Server
  static Future<SupplierModel?> createSupplier(SupplierModel supplier) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("${baseUrl}/api/auth/create_supplier"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(supplier.toJson()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return SupplierModel.fromJson(body);
      } else {
        print("Lỗi Server: ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi API createSupplier: $e");
    }
    return null;
  }
  static Future<List<SupplierModel>> getAllSuppliers() async {
    
    try {
       final token = await _getToken();
      final res = await http.get(Uri.parse("${baseUrl}/api/auth/get_suppliers"),
       headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Gửi kèm token bảo mật
        },);

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final List<dynamic> data = body['data']; // Bóc tách mảng nằm trong trường 'data'
        return data.map((item) => SupplierModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("💥 Lỗi API getAllSuppliers: $e");
    }
    return [];
  }
  static Future<bool> deleteSupplier(String id) async {
    try {
      final res = await http.delete(Uri.parse('${baseUrl}/api/auth/delete_supplier/$id'));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("💥 Lỗi API deleteSupplier: $e");
    }
    return false;
  }
}