import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // baseUrl: const String baseUrl = "http://localhost:3000";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MedicalRecordService {
  static Future<String> addMedicalRecord({
   String? appointmentId,
    String? patientId,
    String? doctorId,
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
    String? symptoms,
    String? treatment,
  }) async {
    try {
      if (status.isEmpty) {
        return "Vui lòng điền đầy đủ Chẩn đoán / Trạng thái.";
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
        try {
          isoDateTime = DateTime.parse(examinationDate).toIso8601String();
        } catch (_) {
          return "Lỗi định dạng ngày hoặc giờ: $e";
        }
      }

      final url = Uri.parse('$baseUrl/api/auth/api/medical-records');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return "Chưa đăng nhập. Không có token.";

      final body = {
        'appointmentId': appointmentId ?? '',
        'patientId': patientId ?? '',
        'doctorId': doctorId ?? '',
        'symptoms': symptoms ?? 'Không ghi nhận triệu chứng',
        'diagnosis': status,
        'treatment': treatment ?? 'Theo dõi định kỳ, điều chỉnh chế độ ăn uống và sinh hoạt.',
        'visitDate': isoDateTime,
        'metrics': {
          'urea': urea,
          'creatinine': creatinine,
          'hba1c': hba1c,
          'cholesterol': cholesterol,
          'triglycerides': triglycerides,
          'hdl': hdl,
          'ldl': ldl,
          'vldl': vldl,
          'bmi': bmi,
        }
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "success";
      } else if (response.statusCode == 400) {
        final bodyData = jsonDecode(response.body);
        return "Lỗi dữ liệu: ${bodyData['message'] ?? bodyData['error'] ?? 'Dữ liệu không hợp lệ'}";
      } else if (response.statusCode == 401) {
        return "Không được phép. Vui lòng đăng nhập lại.";
      } else {
        final bodyData = jsonDecode(response.body);
        return "Lỗi: ${bodyData['message'] ?? bodyData['error'] ?? 'Máy chủ gặp sự cố'}";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalRecord() async {
  try {
    final url = Uri.parse('$baseUrl/api/auth/api_getMedicalRecord');

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
        // Identity
        'id': e['_id']?.toString() ?? '',
        'patientId': e['patientId'] is Map
            ? (e['patientId']['_id']?.toString() ?? '')
            : (e['patientId']?.toString() ?? ''),
        'doctorId': e['doctorId'] is Map
            ? (e['doctorId']['_id']?.toString() ?? '')
            : (e['doctorId']?.toString() ?? ''),
        'patientName': e['patientName']?.toString() ?? '',
        'email': e['patientId'] is Map
            ? (e['patientId']['email']?.toString() ?? e['email']?.toString() ?? '')
            : (e['email']?.toString() ?? ''),
        'patientEmail': e['patientId'] is Map
            ? (e['patientId']['email']?.toString() ?? e['email']?.toString() ?? '')
            : (e['email']?.toString() ?? ''),
        'patientAvatar': e['patientId'] is Map
            ? (e['patientId']['avatar']?.toString() ?? '')
            : '',
        // Clinical data — read actual values from API, never hardcode
        'visitDate': e['visitDate']?.toString() ?? e['examinationDate']?.toString() ?? '',
        'symptoms': e['symptoms']?.toString() ?? '',
        'diagnosis': e['diagnosis']?.toString() ?? '', // [BUG-06 FIX] was: 'Tiểu đường'
        'treatment': e['treatment']?.toString() ?? '',
        // Legacy lab fields (old schema compatibility — will be removed in v2)
        'gender': e['gender']?.toString() ?? '',
        'age': e['age']?.toString() ?? '',
        'urea': e['urea']?.toString() ?? '',
        'creatinine': e['creatinine']?.toString() ?? '',
        'hba1c': e['hba1c']?.toString() ?? '',
        'cholesterol': e['cholesterol']?.toString() ?? '',
        'triglycerides': e['triglycerides']?.toString() ?? '',
        'hdl': e['hdl']?.toString() ?? '',
        'ldl': e['ldl']?.toString() ?? '',
        'vldl': e['vldl']?.toString() ?? '',
        'bmi': e['bmi']?.toString() ?? '',
        'status': e['status']?.toString() ?? '',
        // Blockchain anchor fields
        'pdfUrl': e['pdfUrl']?.toString() ?? '',
        'pdfHash': e['pdfHash']?.toString() ?? '',
        'ipfsHash': e['ipfsHash']?.toString() ?? '',
        'blockchainTx': e['blockchainTx']?.toString() ?? '',
        'createdAt': e['createdAt']?.toString() ?? e['examinationDate']?.toString() ?? '',
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

static Future<Map<String, dynamic>?> getMedicalRecordById(String recordId) async {

  final urlStr = '$baseUrl/api/auth/getmedicalrecordbypatientid/$recordId'; // Đường dẫn API của bạn
 final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
  try {
    final response = await http.get(Uri.parse(urlStr), headers: {
       'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Lỗi lấy chi tiết hồ sơ: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Lỗi kết nối API hồ sơ: $e');
    return null;
  }
}
  static DateTime? tryParseDateTime(String str) {
    if (str.isEmpty) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      try {
        final parts = str.split(' ');
        if (parts.length >= 4) {
          final months = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
          };
          final monthStr = parts[1].toLowerCase().substring(0, 3);
          final day = int.parse(parts[2]);
          final year = int.parse(parts[3]);
          
          int hour = 0;
          int minute = 0;
          int second = 0;
          if (parts.length >= 5 && parts[4].contains(':')) {
            final timeParts = parts[4].split(':');
            if (timeParts.length >= 3) {
              hour = int.parse(timeParts[0]);
              minute = int.parse(timeParts[1]);
              second = int.parse(timeParts[2]);
            }
          }
          
          final m = months[monthStr];
          if (m != null) {
            return DateTime(year, m, day, hour, minute, second);
          }
        }
      } catch (_) {}
      return null;
    }
  }
}
