import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../services/config.dart';

final roomProvider = FutureProvider.family<List<Room>, String?>((ref, specialtyId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  String url = '$baseUrl/rooms';
  if (specialtyId != null && specialtyId.isNotEmpty) {
    url += '?specialtyId=$specialtyId';
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
    return body.map((e) => Room.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load rooms');
  }
});
