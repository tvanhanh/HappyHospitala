import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/specialty.dart';
import '../services/config.dart'; // Contains baseUrl

final specialtyProvider = FutureProvider<List<Specialty>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  final res = await http.get(
    Uri.parse('$baseUrl/specialties'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 200) {
    final List body = jsonDecode(res.body);
    return body.map((e) => Specialty.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load specialties');
  }
});
