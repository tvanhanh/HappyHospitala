import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // baseUrl: const String baseUrl = "http://localhost:3000";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MedicalRecordService {
  static Future<String> addMedicalRecord({
    required String patientName,
    required String email,
    required String examinationDate,
    required String examinationTime,
    String? doctorName,
    String? departmentName,
    String? gender,
    int? age,
    double? urea,
    double? creatinine,
    double? hba1c,
    double? cholesterol,
    double? triglycerides,
    double? hdl,
    double? ldl,
    double? vldl,
    double? bmi,
    required String status,

  }) async {
    try {
      // Kiểm tra các trường bắt buộc
      if (patientName.isEmpty || status.isEmpty) {
        return "Vui lòng điền đầy đủ các trường bắt buộc (Tên bệnh nhân, Chẩn đoán, Trạng thái).";
      }
      String? isoDateTime;
      try {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final timeFormat = DateFormat('HH:mm');
        final date = dateFormat.parse(examinationDate);
        final time = timeFormat.parse(examinationTime);
        final combinedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        isoDateTime = combinedDateTime.toIso8601String(); // Chuyển thành ISO 8601
      } catch (e) {
        return "Lỗi định dạng ngày hoặc giờ: $e";
      }
     

      final url = Uri.parse('$baseUrl/auth/api_addMedicalRecord');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return "Chưa đăng nhập. Không có token.";

      // Chuẩn bị dữ liệu gửi đi, thay null bằng chuỗi rỗng
      final body = {
        'patientName': patientName,
        'email': email,
        'examinationDate': isoDateTime,
        'examinationTime': examinationTime,
        'doctorName': doctorName ?? '', 
        'departmentName': departmentName ?? '', 
        'gender': gender ?? '', 
        'age': age?.toString() ?? '', 
        'urea': urea?.toString() ?? '',
        'creatinine': creatinine?.toString() ?? '',
        'hba1c': hba1c?.toString() ?? '',
        'cholesterol': cholesterol?.toString() ?? '',
        'triglycerides': triglycerides?.toString() ?? '',
        'hdl': hdl?.toString() ?? '',
        'ldl': ldl?.toString() ?? '',
        'vldl': vldl?.toString() ?? '',
        'bmi': bmi?.toString() ?? '',
        'status': status,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

     
      if (response.statusCode == 201) {
        return "success";
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        return "Lỗi dữ liệu: ${body['message'] ?? 'Dữ liệu không hợp lệ'}";
      } else if (response.statusCode == 401) {
        return "Không được phép. Vui lòng đăng nhập lại.";
      } else {
        final body = jsonDecode(response.body);
        return "Lỗi: ${body['message'] ?? 'Máy chủ gặp sự cố'}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalRecord() async {
  try {
    final url = Uri.parse('$baseUrl/auth/api_getMedicalRecord');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print("Chưa đăng nhập. Không có token.");
      return [];
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => {
        'patientName': e['patientName'] ?? '',
        'examinationDate': e['examinationDate'] ?? '',
        'diagnosis': 'Tiểu đường',
        'gender': e['gender'] ?? '',
        'age': e['age'] ?? '',
        'urea': e['urea'] ?? '',
        'creatinine': e['creatinine'] ?? '',
        'hba1c': e['hba1c'] ?? '',
        'cholesterol': e['cholesterol'] ?? '',
        'triglycerides': e['triglycerides'] ?? '',
        'hdl': e['hdl'] ?? '',
        'ldl': e['ldl'] ?? '',
        'vldl': e['vldl'] ?? '',
        'bmi': e['bmi'] ?? '',
        'status': e['status'] ?? '',
        'id': e['_id'] ?? '',
      }).toList();
    } else {
      print("Lỗi khi lấy danh sách: ${response.body}");
      return [];
    }
  } catch (e) {
    print("Lỗi mạng: $e");
    return [];
  }
}


}