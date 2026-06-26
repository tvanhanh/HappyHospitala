import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class SalaryProvider with ChangeNotifier {
  List<dynamic> _salaries = [];
  Map<String, dynamic>? _salarySummary;
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get salaries => _salaries;
  Map<String, dynamic>? get salarySummary => _salarySummary;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchSalaries(int month, int year) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/salaries?month=$month&year=$year'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _salaries = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy danh sách lương';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary(int month, int year) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/salaries/summary?month=$month&year=$year'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _salarySummary = data['data'];
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<bool> generateSalaries(int month, int year) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/salaries/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'month': month, 'year': year}),
      );

      if (response.statusCode == 200) {
        await fetchSalaries(month, year);
        await fetchSummary(month, year);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> paySalary(String id, int currentMonth, int currentYear) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/salaries/$id/pay'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchSalaries(currentMonth, currentYear);
        await fetchSummary(currentMonth, currentYear);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
