import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class PremiumProvider with ChangeNotifier {
  List<dynamic> _packages = [];
  List<dynamic> _subscriptions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get packages => _packages;
  List<dynamic> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchPackages() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/premiums/packages'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _packages = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy danh sách gói';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubscriptions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/premiums/subscriptions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _subscriptions = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy danh sách đăng ký';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPackage(Map<String, dynamic> pkgData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/premiums/packages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(pkgData),
      );

      if (response.statusCode == 201) {
        await fetchPackages();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePackage(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/premiums/packages/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _packages.removeWhere((p) => p['_id'] == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
