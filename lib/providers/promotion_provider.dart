import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class PromotionProvider with ChangeNotifier {
  List<dynamic> _promotions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchPromotions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) throw Exception("Chưa đăng nhập");

      final response = await http.get(
        Uri.parse('$baseUrl/api/promotions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _promotions = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy danh sách khuyến mãi';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPromotion(Map<String, dynamic> promoData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/promotions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(promoData),
      );

      if (response.statusCode == 201) {
        await fetchPromotions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePromotion(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/promotions/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _promotions.removeWhere((p) => p['_id'] == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
