import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import './config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MedicalRecordBlockchainService {
  static Future<Map<String, dynamic>> addMedicalRecord({
    required String patientId,
    required String doctorId,
    required String patientName, 
    required String symptoms,
    required DateTime visitDate,
    required String diagnosis,
    required String treatment,
    required List<XFile> attachments,
  }) async {
    final url = Uri.parse("$baseUrl/auth/api/medicalrecord-blockchain");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var request = http.MultipartRequest("POST", url);

    // Body text fields
    request.fields["patientId"] = patientId;
    request.fields["doctorId"] = doctorId;
    request.fields["patientName"] = patientName;
    request.fields["symptoms"] = symptoms;
    request.fields["diagnosis"] = diagnosis;
    request.fields["treatment"] = treatment;
    request.fields["visitDate"] = visitDate.toIso8601String();

    // Add files
    for (final x in attachments) {
      if (kIsWeb) {
        // Web: dùng bytes, không dùng dart:io
        final bytes = await x.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "attachments",
            bytes,
            filename: basename(x.name),
          ),
        );
      } else {
        // Mobile / desktop: dùng đường dẫn file
        request.files.add(
          await http.MultipartFile.fromPath(
            "attachments",
            x.path,
            filename: basename(x.path),
          ),
        );
      }
    }

    // Add token if exists
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception("Lỗi tạo hồ sơ: ${response.statusCode} - $responseBody");
    }
  }

   static Future<List<Map<String, dynamic>>> listMedicalRecal() async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/api/list-medical-records');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body is Map<String, dynamic> ? body['records'] : body;

        return data.map<Map<String, dynamic>>((e) {
          final metrics = e['metrics'] is Map ? e['metrics'] : {};
          return {
            
            '_id': e['_id']?.toString() ?? '',
            'patientId': e['patientId']?.toString() ?? '',
            'doctorId': e['doctorId']?.toString() ?? '',
            'patientName': e['patientName']?.toString() ?? '',
            'email': e['email']?.toString() ?? e['patientEmail']?.toString() ?? '',
            'visitDate': e['visitDate'] ?? e['examinationDate'] ?? '',
            'examinationTime': e['examinationTime']?.toString() ?? '',
            'symptoms': e['symptoms']?.toString() ?? '',
            'diagnosis': e['diagnosis']?.toString() ?? '',
            'treatment': e['treatment']?.toString() ?? '',
            'gender': e['gender']?.toString() ?? '',
            'age': e['age']?.toString() ?? '',
            'status': e['status']?.toString() ?? '',
            'createdAt': e['createdAt']?.toString() ?? '',

            // 🧪 Chỉ số cận lâm sàng tiểu đường
      'urea': metrics['urea']?.toString() ?? '',
          'creatinine': metrics['creatinine']?.toString() ?? '',
          'hba1c': metrics['hba1c']?.toString() ?? '',
          'cholesterol': metrics['cholesterol']?.toString() ?? '',
          'triglycerides': metrics['triglycerides']?.toString() ?? '',
          'hdl': metrics['hdl']?.toString() ?? '',
          'ldl': metrics['ldl']?.toString() ?? '',
          'vldl': metrics['vldl']?.toString() ?? '',
          'bmi': metrics['bmi']?.toString() ?? '',
            // 🔐 Các trường neo Blockchain mật mã
            'pdfUrl': e['pdfUrl']?.toString() ?? '',
            'pdfHash': e['pdfHash']?.toString() ?? '',
            'ipfsHash': e['ipfsHash']?.toString() ?? '',
            'blockchainTx': e['blockchainTx']?.toString() ?? '',
          };
        }).toList();
      } else {
        print("Lỗi khi lấy danh sách: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng: $e");
      return [];
    }
  }  static Future<Map<String, dynamic>?> getMedicalRecordDetail(String id) async {
  try {
    // ✅ 1. SỬA: Dùng trực tiếp tham số 'id' được truyền vào hàm
    final url = Uri.parse('$baseUrl/auth/api/medical-records/$id');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Chưa đăng nhập. Không tìm thấy token.");
      return null;
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } else {
      print('Lỗi từ Server (${response.statusCode}): ${response.body}');
    }
  } catch (e) {
    print('Lỗi mạng/hệ thống khi lấy chi tiết bệnh án: $e');
  }
  return null;
}
static Future<List<Map<String, dynamic>>> searchMedicalRecordsByPatientId(
    String patientId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/api/medical-records-search?patientId=$patientId");
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print("❌ Không có token");
        return [];
      }
      print("CALL API: $url");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['records'] ?? [];

        return data.map<Map<String, dynamic>>((e) {
          return {
            '_id': e['_id'],
            'patientId': e['patientId'],
            'patientName': e['patientName'],
            'doctorId': e['doctorId'],
            'doctorName': e['doctorName'],
            'symptoms': e['symptoms'],
            'diagnosis': e['diagnosis'],
            'treatment': e['treatment'],
            'visitDate': e['visitDate'],
            'pdfUrl': e['pdfUrl'],
            'blockchainTx': e['blockchainTx'],
            'blockchainNetwork': e['blockchainNetwork'],
            'blockNumber': e['blockNumber'],
            'ipfsHash': e['ipfsHash'] ?? e['ipfsCID'] ?? 'N/A', // Đảm bảo map thêm mã hash IPFS cho UI
          };
        }).toList();
      } else {
        print("❌ Backend trả lỗi: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi tra cứu bệnh án: $e");
    }
    return [];
  }
static Future<File?> downloadSecurePdf(String recordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$baseUrl/api/auth/download-pdf/$recordId');

      print("📂 Đang tải PDF bảo mật từ: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/record_$recordId.pdf');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? "Bạn chưa được cấp quyền xem tài liệu gốc này.");
      } else {
        throw Exception("Lỗi máy chủ (${response.statusCode}): Không thể tải file PDF gốc.");
      }
    } catch (e) {
      print("❌ Lỗi downloadSecurePdf: $e");
      rethrow;
    }
    }
    static Future<bool> respondToAccessRequest({
    required String recordId,
    required String staffId,
    required String status, // Nhận vào: "approved" hoặc "rejected"
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('$baseUrl/api/auth/approve'); 

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "recordId": recordId,
          "staffId": staffId,
          "status": status, // "approved" hoặc "rejected"
        }),
      );

      final data = jsonDecode(response.body);

      // Khớp với cấu hình Backend trả về thành công: res.status(200).json({ ok: true, ... })
      if (response.statusCode == 200 && data['ok'] == true) {
        return true;
      } else {
        // Trích xuất lỗi từ backend nếu có (ví dụ: "Bạn không phải chủ sở hữu hồ sơ...")
        throw Exception(data['error'] ?? "Xử lý phản hồi yêu cầu thất bại.");
      }
    } catch (e) {
      print("❌ Lỗi respondToAccessRequest: $e");
      rethrow;
    }
  }
static Future<bool> sendAccessRequest(String recordId, {String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$baseUrl/api/auth/request');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "recordId": recordId,
          "reason": reason ?? "Yêu cầu kiểm tra chéo dữ liệu bệnh án hệ thống." // Truyền lý do thật từ Dialog Flutter
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? "Gửi yêu cầu xin quyền truy cập thất bại.");
      }
    } catch (e) {
      print("❌ Lỗi sendAccessRequest: $e");
      rethrow;
    }
}
 
 static Future<List<Map<String, dynamic>>> getDoctorRequestsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // 📝 URL Khớp chính xác với router Node.js: /requests/doctor-history
      final url = Uri.parse('$baseUrl/api/auth/requests/doctor-history');

      print("⏳ Đang đồng bộ lịch sử yêu cầu từ: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? [];
        
        // Trả về danh sách đã format chuẩn hóa 100% các trường cho UI hiển thị
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print("❌ Lỗi khi lấy lịch sử từ backend: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Lỗi hệ thống tại getDoctorRequestsHistory: $e");
      return [];
    }
  }
 }

