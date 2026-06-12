import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class ReportProvider with ChangeNotifier {
  Map<String, dynamic>? _overviewStats;
  Map<String, dynamic>? _revenueReport;
  List<dynamic>? _doctorPerformance;
  bool _isLoading = false;
  String _errorMessage = '';

  Map<String, dynamic>? get overviewStats => _overviewStats;
  Map<String, dynamic>? get revenueReport => _revenueReport;
  List<dynamic>? get doctorPerformance => _doctorPerformance;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchOverview() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/overview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _overviewStats = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy tổng quan báo cáo';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRevenueReport(String period) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/revenue?period=$period'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _revenueReport = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy báo cáo doanh thu';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDoctorPerformance() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/reports/doctors'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _doctorPerformance = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy báo cáo bác sĩ';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
