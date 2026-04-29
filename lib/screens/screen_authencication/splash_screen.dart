import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("token");
    String? role = prefs.getString("role");

    await Future.delayed(Duration(seconds: 1));

    if (token != null && token.isNotEmpty) {
      if (role == 'admin') {
        context.go('/admin');
      } else if (role == 'patient') {
        context.go('/home');
      } else if (role == 'doctor') {
        context.go('/doctor');
      } else if (role == 'staff') {
        context.go('/staff');
      } else {
        context.go('/login'); // fallback
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
