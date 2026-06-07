import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class AdminStats {
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int totalSpecialties;
  final int totalRooms;

  AdminStats({
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.totalSpecialties,
    required this.totalRooms,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalDoctors: json['totalDoctors'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      totalSpecialties: json['totalSpecialties'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
    );
  }
}

class ChartData {
  final String name;
  final int count;

  ChartData({required this.name, required this.count});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final res = await http.get(
    Uri.parse('$baseUrl/admin/stats'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 200) {
    return AdminStats.fromJson(jsonDecode(res.body));
  } else {
    throw Exception('Failed to load admin stats: ${res.body}');
  }
});

final chartDataProvider = FutureProvider<List<ChartData>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final res = await http.get(
    Uri.parse('$baseUrl/admin/chart-data'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 200) {
    final List body = jsonDecode(res.body);
    return body.map((e) => ChartData.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load chart data: ${res.body}');
  }
});

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? avatar;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.avatar,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Chưa cập nhật',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      status: json['status'] ?? 'activity',
      avatar: json['profile']?['avatar'] ?? json['avatar'],
    );
  }
}

final usersProvider = FutureProvider<List<AppUser>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final res = await http.get(
    Uri.parse('$baseUrl/admin/users'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode == 200) {
    final List body = jsonDecode(res.body);
    return body.map((e) => AppUser.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load users: ${res.body}');
  }
});
