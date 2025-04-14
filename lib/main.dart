import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screen_doctor/home.dart';
import 'screens/screen_staff/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt lịch khám bệnh',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Định nghĩa route ban đầu là '/'
      routes: {
        '/': (context) => HomeScreen(), // Thêm màn hình chính vào '/'
        '/home': (context) => HomeScreen(),
        '/thankyou': (context) => ThankYouScreen(),
        '/': (context) => LoginScreen(),
        '/admin': (context) => AdminDashboard(),
        '/doctor': (context) => DoctorDashboard(),
        '/staff': (context) => StaffDashboard(),
      },
    );
  }
}
