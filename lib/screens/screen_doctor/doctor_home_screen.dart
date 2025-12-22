import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorDashboard extends StatelessWidget {
  DoctorDashboard({super.key});

  final List<_DashboardItem> items = [
    _DashboardItem(
      "Xem lịch hẹn bệnh nhân",
      Icons.calendar_today,
      '/doctor/appointments',
    ),
    _DashboardItem(
      "Hồ sơ bệnh án",
      Icons.assignment,
      '/doctor/list-medical',
    ),
    _DashboardItem(
      "Gửi đơn thuốc/xét nghiệm",
      Icons.receipt_long,
      '/prescription',
    ),
    _DashboardItem(
      "Quản lý bệnh nhân",
      Icons.people,
      '/patient-management',
    ),
    _DashboardItem(
      "Xem kết quả phân loại",
      Icons.bar_chart,
      '/classification-results',
    ),
    _DashboardItem(
      "Gửi tư vấn",
      Icons.message,
      '/consultation',
    ),
    _DashboardItem(
      "Theo dõi tiến trình bệnh nhân",
      Icons.track_changes,
      '/progress-tracking',
    ),
    _DashboardItem(
      "Tạo báo cáo tổng quan",
      Icons.analytics,
      '/statistics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Bác Sĩ"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.local_hospital, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text("Bác Sĩ",
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                  Text("Chăm sóc bệnh nhân",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ...items.map(
              (item) => ListTile(
                leading: Icon(item.icon, color: Colors.teal),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.route); // ✅ GoRouter
                },
              ),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatBox("Tổng BN", "120", Icons.person),
                    _StatBox("Cần theo dõi", "30", Icons.warning),
                    _StatBox("Cần khám", "10", Icons.local_hospital),
                  ],
                ),
              ),
            ),
          ),

          // GRID CHỨC NĂNG
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: items.map((item) {
                return InkWell(
                  onTap: () => context.go(item.route), 
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon,
                              size: 40, color: Colors.teal),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                          ),
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
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;

  _DashboardItem(this.title, this.icon, this.route);
}

class _StatBox extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;

  const _StatBox(this.label, this.count, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.teal),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
