import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

// 🟢 IMPORT CÁC MODEL CẦN THIẾT
import '../models/medicine_model.dart';
// Hãy đảm bảo đường dẫn và tên file bên dưới khớp với file Model đơn thuốc của bạn:
import '../models/prescription_model.dart'; 

class ApiPrescription {
  
  // Hàm lấy token bảo mật từ bộ nhớ thiết bị
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }

  // ================= API: TẠO ĐƠN THUỐC MỚI (BÁC SĨ) =================
  static Future<bool> createPrescription({
    required String appointmentId,
    required String diagnosis,
    required String patientId,
    required String patientName,
    String? patientPhone,    
    String? birthDate,     
    String? gender,          
    String? healthInsurance,
    required List<Map<String, dynamic>> medicines,
    String? doctorId,    
    String? doctorName,
  }) async {
    try {
      final token = await _getToken();
      
      final Map<String, dynamic> bodyData = {
        "appointmentId": appointmentId,
        "diagnosis": diagnosis,
        "patientId": patientId,
        "patientName": patientName,
        "patientPhone": patientPhone,    
        "birthDate": birthDate,         
        "gender": gender,
        "healthInsurance": healthInsurance, 
        "medicines": medicines,
        "doctorId": doctorId,      
        "doctorName": doctorName,
      };

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/create_prescription"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        print("Lỗi Server (createPrescription): ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("💥 Lỗi kết nối API createPrescription: $e");
      return false;
    }
  }
  static Future<List<PrescriptionModel>> getPendingPrescriptions() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_prescriptions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> data = body['data'] ?? []; 
        return data.map((item) => PrescriptionModel.fromJson(item)).toList();
      } else {
        print("Lỗi Server (getPendingPrescriptions): ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API getPendingPrescriptions: $e");
    }
    return [];
  }
  static Future<List<PrescriptionModel>> getCompletedPrescriptions() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/api/auth/get_prescriptions?status=completed"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> data = body['data'] ?? []; 
        return data.map((item) => PrescriptionModel.fromJson(item)).toList();
      } else {
        print("Lỗi Server (getCompletedPrescriptions): ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API getCompletedPrescriptions: $e");
    }
    return [];
  }
  static Future<bool> updatePrescriptionStatus(String prescriptionId, String status) async {
    try {
      final token = await _getToken();

      final res = await http.put(
        Uri.parse("$baseUrl/api/auth/update_status_prescriptions/$prescriptionId/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "status": status,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true; 
      } else {
        print("Lỗi Server (updatePrescriptionStatus): ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print(" Lỗi kết nối API updatePrescriptionStatus: $e");
      return false;
    }
  }
}