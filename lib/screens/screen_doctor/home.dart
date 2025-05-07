import 'package:flutter/material.dart';
import '../../widgets/role_based_nav_drawer.dart';
import './chatAI_screen.dart';
import 'appointment_page.dart';
import 'prescription_page.dart';
import 'patient_management_page.dart';
import 'classification_results_page.dart';
import 'consultation_page.dart';
import 'progress_tracking_page.dart';
import 'patient_discussion_page.dart';

void main() => runApp(DoctorApp());

class DoctorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng Dụng Bác Sĩ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: DoctorDashboard(),
      routes: {
        '/appointments': (context) => AppointmentPage(),
        '/prescription': (context) => PrescriptionPage(),
        '/patient-management': (context) => PatientManagementPage(),
        '/classification-results': (context) => ClassificationResultsPage(),
        '/consultation': (context) => ConsultationPage(),
        '/progress-tracking': (context) => ProgressTrackingPage(),
        '/patient-discussion': (context) => PatientDiscussionPage(),
        '/statistics': (context) => StatisticsPage(),
      },
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> features = [
    {
      'title': 'Lịch hẹn khám',
      'icon': Icons.calendar_today,
      'route': '/appointments',
    },
    {
      'title': 'Đơn thuốc / Xét nghiệm',
      'icon': Icons.medical_services,
      'route': '/prescription',
    },
    {
      'title': 'Quản lý bệnh nhân',
      'icon': Icons.person,
      'route': '/patient-management',
    },
    {
      'title': 'Kết quả phân loại',
      'icon': Icons.analytics,
      'route': '/classification-results',
    },
    {
      'title': 'Gửi tư vấn',
      'icon': Icons.send,
      'route': '/consultation',
    },
    {
      'title': 'Theo dõi tiến trình',
      'icon': Icons.track_changes,
      'route': '/progress-tracking',
    },
    {
      'title': 'Thảo luận với bệnh nhân',
      'icon': Icons.chat,
      'route': '/patient-discussion',
    },
    {
      'title': 'Thống kê bệnh án',
      'icon': Icons.bar_chart,
      'route': '/statistics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bảng Điều Khiển Bác Sĩ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thống kê tổng quan
            Card(
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Thống Kê Bệnh Án',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('• Tổng số bệnh nhân: 120',
                        style: TextStyle(color: Colors.white)),
                    Text('• Cần theo dõi: 30',
                        style: TextStyle(color: Colors.white)),
                    Text('• Cần thăm khám: 10',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Danh sách chức năng
            Expanded(
              child: GridView.builder(
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // hiển thị 2 cột
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, feature['route']);
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(feature['icon'], size: 40, color: Colors.blue),
                            const SizedBox(height: 10),
                            Text(
                              feature['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Trang thống kê có nút chat AI
class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thống Kê Bệnh Án')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Thống Kê Hiện Tại',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Tổng số bệnh nhân: 120'),
                const Text('Bệnh nhân cần theo dõi: 30'),
                const Text('Bệnh nhân cần thăm khám: 10'),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Trò chuyện với AI"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
