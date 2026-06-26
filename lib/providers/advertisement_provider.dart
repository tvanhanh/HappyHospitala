import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';

class AdvertisementProvider with ChangeNotifier {
  List<dynamic> _ads = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get ads => _ads;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchAds() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/advertisements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _ads = data['data'];
        }
      } else {
        _errorMessage = 'Lỗi lấy danh sách quảng cáo';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAd(Map<String, dynamic> adData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/advertisements'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(adData),
      );

      if (response.statusCode == 201) {
        await fetchAds();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAd(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/advertisements/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _ads.removeWhere((a) => a['_id'] == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
