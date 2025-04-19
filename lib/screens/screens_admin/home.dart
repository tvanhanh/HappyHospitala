import 'package:flutter/material.dart';
import 'patient_list.dart';
import 'security_ayth.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_hospital, size: 48, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Quản trị viên",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Tổng quan'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Bệnh nhân'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PatientListScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Lịch hẹn'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Bác sĩ'),
              onTap: () {},
            ),
            ListTile(
                leading: Icon(Icons.medical_services),
                title: Text('Nhân viên'),
                onTap: () {}),
            ListTile(
                leading: Icon(Icons.add_business_sharp),
                title: Text('Quản lý thuốc và kho'),
                onTap: () {}),
            ListTile(
                leading: Icon(Icons.bar_chart_sharp),
                title: Text('Báo cáo và Thống kê'),
                onTap: () {}),
            ListTile(
                leading: Icon(Icons.business),
                title: Text('Quản lý phòng ban'),
                onTap: () {}),
            ListTile(
                leading: Icon(Icons.security_sharp),
                title: Text('Bảo mật và Phân quyền'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserManagementScreen()),
                  );
                }),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Thống kê
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Bệnh nhân", "120", Colors.blue),
                _buildStatCard("Lịch hẹn", "20", Colors.green),
                _buildStatCard("Bác sĩ", "6", Colors.orange),
              ],
            ),
            SizedBox(height: 20),
            // Form nhập bác sĩ
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Thêm bác sĩ mới",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Họ tên"),
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Chuyên khoa"),
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Email"),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Lưu"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Chọn ngày
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Chọn ngày thống kê",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        // mở date picker
                      },
                      icon: Icon(Icons.date_range),
                      label: Text("Chọn ngày"),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(Icons.analytics, size: 32, color: color),
              SizedBox(height: 8),
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
