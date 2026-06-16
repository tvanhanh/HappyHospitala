import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/access_request_model.dart'; 
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessRequestApiService {
  Future<List<AccessRequestModel>> getSentRequestsHistory(String recordId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/api/auth/sent-history?recordId=$recordId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);   
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> listRaw = responseData['data'];   
          // Map danh sách thô từ JSON sang danh sách Model chuẩn hóa
          return listRaw.map((item) => AccessRequestModel.fromJson(item)).toList();
        }
      } else {
        print("⚠️ Lỗi từ Server (${response.statusCode}): ${response.body}");
      }
      return [];
    } catch (e) {
      print("❌ Lỗi kết nối API AccessRequest: $e");
      return [];
    }
  }
  Future<List<AccessRequestModel>> getReceivedRequests() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/api/auth/received-requests');
      
      print("🚀 [Flutter API] Đang gọi lấy danh sách yêu cầu đã nhận...");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);   
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> listRaw = responseData['data'];   
          
          // Map danh sách từ JSON sang danh sách Model giống hàm trên của bạn
          return listRaw.map((item) => AccessRequestModel.fromJson(item)).toList();
        }
      } else {
        print("⚠️ Lỗi từ Server khi lấy yêu cầu nhận (${response.statusCode}): ${response.body}");
      }
      return [];
    } catch (e) {
      print("❌ Lỗi kết nối API lấy yêu cầu nhận: $e");
      return [];
    }
  }
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}