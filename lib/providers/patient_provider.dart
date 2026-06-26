import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

final patientProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  String url = '$baseUrl/api/admin/patients';
  if (query.isNotEmpty) {
    url += '?search=$query';
  }

  final res = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 200) {
    final List body = jsonDecode(res.body);
    return body.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
  } else {
    throw Exception('Failed to load patients');
  }
});
