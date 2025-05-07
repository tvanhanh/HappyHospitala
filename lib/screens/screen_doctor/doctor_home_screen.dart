import 'package:flutter/material.dart';
import 'home.dart';
import 'appointment_page.dart';
import 'prescription_page.dart';
import 'patient_management_page.dart';

class DoctorHomePage extends StatefulWidget {
  @override
  _DoctorHomePageState createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    //DoctorDashboardPage(),
    AppointmentPage(),
    PrescriptionPage(),
    PatientManagementPage(),
    StatisticsPage(),
  ];

  final List<String> _titles = [
    'Trang Bác Sĩ',
    'Lịch Hẹn',
    'Đơn Thuốc',
    'Bệnh Nhân',
    'Thống Kê',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Lịch hẹn'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'Đơn thuốc'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Bệnh nhân'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Thống kê'),
        ],
      ),
    );
  }
}
