import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import './config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      final url = Uri.parse('$baseUrl/auth/api/list-medical-records');
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
          return {
            
            '_id': e['_id'],
            'patientId': e['patientId'],
            'patientName': e['patientName'],
            'visitDate': e['visitDate'],
            'createdAt': e['createdAt'],
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
  }
  static Future<Map<String, dynamic>?> getMedicalRecordDetail(String id) async {
  try {
    final url = Uri.parse('$baseUrl/auth/api/medical-records/$id');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body['record']);
    }
  } catch (e) {
    print('Lỗi lấy chi tiết bệnh án: $e');
  }
  return null;
}
}


