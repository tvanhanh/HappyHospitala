import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import '../models/import_model.dart';
class ApiImport {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }
 static Future<ImportModel?> createImportRecord(ImportModel importRecord) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/create_importmedicine"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        // Chuyển đối tượng Model thành chuỗi JSON ở đây bằng .toJson()
        body: jsonEncode(importRecord.toJson()), 
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        
        if (body['data'] != null) {
          return ImportModel.fromJson(body['data']);
        }
      } else {
        final errorBody = jsonDecode(res.body);
        print("Lỗi Server (createImportRecord): ${res.statusCode} - ${errorBody['message'] ?? ''}");
      }
    } catch (e) {
      print("💥 Lỗi kết nối API createImportRecord: $e");
    }
    return null;
  }
  static Future<List<ImportModel>> fetchImportRecords() async {
  try {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse("$baseUrl/api/auth/get_importmedicine"), // Thay đổi URL endpoint cho đúng với Backend của bạn
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['data'] != null) {
        final List listData = body['data'];
        return listData.map((item) => ImportModel.fromJson(item)).toList();
      }
    } else {
      print("Lỗi Server (fetchImportRecords): ${res.statusCode}");
    }
  } catch (e) {
    print("💥 Lỗi kết nối API fetchImportRecords: $e");
  }
  return [];
}
}