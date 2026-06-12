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

    if (token != null && token.isNotEmpty && role != null) {
      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'doctor':
          context.go('/doctor');
          break;
        case 'receptionist':
        case 'staff': // backward compat
          context.go('/receptionist/dashboard');
          break;
        case 'cashier':
          context.go('/cashier');
          break;
        case 'pharmacy':
          context.go('/pharmacy');
          break;
        case 'patient':
        default:
          context.go('/home'); // Auth patient or unknown
          break;
      }
    } else {
      // Default to Login Screen instead of guest Mode
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
