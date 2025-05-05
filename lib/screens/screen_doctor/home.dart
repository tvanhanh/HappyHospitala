import 'package:flutter/material.dart';

void main() => runApp(DoctorApp());

class DoctorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng Dụng Bác Sĩ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        '/statistics': (context) => StatisticsPage(), // Thêm trang thống kê
      },
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trang Bác Sĩ')),
      body: Column(
        children: [
          // Thống kê bệnh án (có thể thay bằng API thực tế sau)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blueAccent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thống Kê Bệnh Án',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Tổng số bệnh nhân: 120',
                        style: TextStyle(color: Colors.white)),
                    Text('Số bệnh nhân cần theo dõi: 30',
                        style: TextStyle(color: Colors.white)),
                    Text('Số bệnh nhân cần thăm khám: 10',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          // Các chức năng
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text('Xem lịch hẹn khám của bệnh nhân'),
                  onTap: () {
                    Navigator.pushNamed(context, '/appointments');
                  },
                ),
                ListTile(
                  title: Text('Gửi đơn thuốc / Chỉ định xét nghiệm'),
                  onTap: () {
                    Navigator.pushNamed(context, '/prescription');
                  },
                ),
                ListTile(
                  title: Text('Tạo báo cáo tổng quan tình hình bệnh nhân'),
                  onTap: () {
                    // Handle báo cáo logic
                  },
                ),
                ListTile(
                  title: Text('Quản lý nhóm bệnh nhân'),
                  onTap: () {
                    // Handle group management logic
                  },
                ),
                ListTile(
                  title: Text('Quản lý bệnh nhân'),
                  onTap: () {
                    Navigator.pushNamed(context, '/patient-management');
                  },
                ),
                ListTile(
                  title: Text('Xem kết quả phân loại'),
                  onTap: () {
                    Navigator.pushNamed(context, '/classification-results');
                  },
                ),
                ListTile(
                  title: Text('Gửi tư vấn'),
                  onTap: () {
                    Navigator.pushNamed(context, '/consultation');
                  },
                ),
                ListTile(
                  title: Text('Theo dõi tiến trình bệnh nhân'),
                  onTap: () {
                    Navigator.pushNamed(context, '/progress-tracking');
                  },
                ),
                ListTile(
                  title: Text('Thảo luận với bệnh nhân'),
                  onTap: () {
                    Navigator.pushNamed(context, '/patient-discussion');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Các màn hình chức năng khác
class AppointmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch Hẹn Khám')),
      body: Center(
        child: Text('Danh sách lịch hẹn khám của bệnh nhân'),
      ),
    );
  }
}

class PrescriptionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gửi Đơn Thuốc / Chỉ Định Xét Nghiệm')),
      body: Center(
        child: Text('Gửi đơn thuốc và chỉ định xét nghiệm'),
      ),
    );
  }
}

class PatientManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản Lý Bệnh Nhân')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Thêm hồ sơ bệnh nhân'),
            onTap: () {
              // Handle add patient logic
            },
          ),
          ListTile(
            title: Text('Xóa bệnh nhân'),
            onTap: () {
              // Handle delete patient logic
            },
          ),
          ListTile(
            title: Text('Sửa bệnh nhân'),
            onTap: () {
              // Handle edit patient logic
            },
          ),
          ListTile(
            title: Text('Tìm kiếm bệnh nhân'),
            onTap: () {
              // Handle search patient logic
            },
          ),
        ],
      ),
    );
  }
}

class ClassificationResultsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kết Quả Phân Loại')),
      body: Center(
        child: Text('Hiển thị kết quả phân loại bệnh nhân'),
      ),
    );
  }
}

class ConsultationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gửi Tư Vấn')),
      body: Center(
        child: Text('Gửi tư vấn cho bệnh nhân'),
      ),
    );
  }
}

class ProgressTrackingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theo Dõi Tiến Trình Bệnh Nhân')),
      body: Center(
        child: Text('Theo dõi tiến trình điều trị của bệnh nhân'),
      ),
    );
  }
}

class PatientDiscussionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thảo Luận Với Bệnh Nhân')),
      body: Center(
        child: Text('Giao diện nhắn tin với bệnh nhân'),
      ),
    );
  }
}

// Trang thống kê bệnh án
class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thống Kê Bệnh Án')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tổng số bệnh nhân: 120'),
            Text('Số bệnh nhân cần theo dõi: 30'),
            Text('Số bệnh nhân cần thăm khám: 10'),
          ],
        ),
      ),
    );
  }
}
