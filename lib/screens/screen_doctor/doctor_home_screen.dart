import 'package:flutter/material.dart';
import 'appointment_page.dart';
import 'prescription.dart';
import 'patient_management.dart';
import 'classification_results.dart';
import 'consultation.dart';
import 'progress_tracking.dart';
import 'statistics.dart';

void main() => runApp(DoctorApp());

class DoctorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng Dụng Bác Sĩ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DoctorDashboard(),
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  final List<_DashboardItem> items = [
    _DashboardItem("Xem lịch hẹn bệnh nhân", Icons.calendar_today, AppointmentPage()),
    _DashboardItem("Gửi đơn thuốc/xét nghiệm", Icons.receipt_long, PrescriptionPage()),
    _DashboardItem("Quản lý bệnh nhân", Icons.people, PatientManagementPage()),
    _DashboardItem("Xem kết quả phân loại", Icons.bar_chart, ClassificationResultsPage()),
    _DashboardItem("Gửi tư vấn", Icons.message, ConsultationPage()),
    _DashboardItem("Theo dõi tiến trình bệnh nhân", Icons.track_changes, ProgressTrackingPage()),
    _DashboardItem("Tạo báo cáo tổng quan", Icons.analytics, StatisticsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang Bác Sĩ"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_hospital, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text("Bác Sĩ", style: TextStyle(color: Colors.white, fontSize: 24)),
                  Text("Chăm sóc bệnh nhân", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ...items.map((item) => ListTile(
              leading: Icon(item.icon, color: Colors.teal),
              title: Text(item.title),
              onTap: () {
                Navigator.pop(context); // Đóng Drawer trước khi điều hướng
                Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
              },
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          // THỐNG KÊ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              color: Colors.teal.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox("Tổng BN", "120", Icons.person),
                    _buildStatBox("Cần theo dõi", "30", Icons.warning),
                    _buildStatBox("Cần khám", "10", Icons.local_hospital),
                  ],
                ),
              ),
            ),
          ),
          // CHỨC NĂNG
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(12),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: items.map((item) {
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 40, color: Colors.teal),
                          SizedBox(height: 10),
                          Text(item.title, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.teal[900]),
        SizedBox(height: 8),
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Widget page;

  _DashboardItem(this.title, this.icon, this.page);
}