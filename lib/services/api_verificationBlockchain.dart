import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Đảm bảo đã định nghĩa baseUrl trong này

// -----------------------------------------------------------------
// MODEL HỨNG DỮ LIỆU XÁC THỰC TOÀN VẸN (HASH COMPARISON)
// -----------------------------------------------------------------
class VerificationResult {
  final bool isVerifiedSuccess;
  final String blockchainHash;
  final String computedHash;
  final int? blockNumber;
  final String? blockchainTx;

  VerificationResult({
    required this.isVerifiedSuccess,
    required this.blockchainHash,
    required this.computedHash,
    this.blockNumber,
    this.blockchainTx,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isVerifiedSuccess: json['isVerifiedSuccess'] ?? false,
      blockchainHash: json['blockchainHash'] ?? '',
      computedHash: json['computedHash'] ?? '',
      blockNumber: json['blockNumber'],
      blockchainTx: json['blockchainTx'],
    );
  }
}

// -----------------------------------------------------------------
// SERVICE ĐIỀU HƯỚNG TƯƠNG TÁC API BACKEND
// -----------------------------------------------------------------
class BlockchainApiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }
  
 Future<VerificationResult?> verifyRecordIntegrity(String recordId) async {
  try {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-blockchain'), 
      headers: headers,
      body: jsonEncode({"recordId": recordId}), 
    );

    print("Verify Status: ${response.statusCode}");
    print("Verify Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['ok'] == true || data['success'] == true) {
        return VerificationResult.fromJson(data);
      }
    }
    return null;
  } catch (e) {
    print("Lỗi kết nối API xác thực: $e");
    return null;
  }
}
  Future<Map<String, dynamic>> createAccessRequest({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String reason,
    required String requestedRecordId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/request"),
        headers: headers,
        body: jsonEncode({
          "patientId": patientId,
          "doctorId": doctorId,
          "doctorName": doctorName,
          "reason": reason,
          "requestedRecordId": requestedRecordId,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data; // Trả về để UI handle báo thành công hay thất bại
    } catch (e) {
      print("Lỗi khi gửi yêu cầu truy cập: $e");
      return {"ok": false, "error": e.toString()};
    }
  }
  Future<bool> respondToAccessRequest(String requestId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/api/auth/respond"),
        headers: headers,
        body: jsonEncode({
          "requestId": requestId,
          "status": status, // "approved"
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print("Lỗi phản hồi yêu cầu cấp quyền: $e");
      return false;
    }
  }
  Future<Map<String, dynamic>> getMedicalRecordDetailForDoctor({
    required String recordId,
    required String doctorId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/api/auth/record-detail?recordId=$recordId&doctorId=$doctorId"),
        headers: headers,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data; 
      // Nếu data['ok'] == false và data['error'] == 'ACCESS_DENIED'
      // -> Flutter sẽ hiểu để bật Popup Form bắt nhập lý do gửi yêu cầu.
    } catch (e) {
      print("Lỗi lấy chi tiết hồ sơ bệnh án: $e");
      return {"ok": false, "error": e.toString(), "message": "Lỗi kết nối máy chủ"};
    }
  }
}