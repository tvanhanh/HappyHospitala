import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/report_statistics.dart';
import 'patient_list.dart';
import 'security_screens/security_ayth.dart';
import 'appoitment.dart';
import 'overview.dart';
import 'departmenr_screens/department_management.dart';
import 'doctor_list.dart';
import 'inventory_management.dart';
import 'log_out.dart';
import 'staff_list.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedMenuIndex = 0;

  final List<Widget> pages = [
    DashboardOverview(),
    PatientListScreen(),
    AppointmentListScreen(),
    DoctorListScreen(),
    StaffManagement(),
    MedicineInventory(),
    MonthlyReportScreen(),
    DepartmentManagement(),
    UserManagementScreen(),

    // 8: Bảo mật & phân quyền
  ];

  void onSelectMenu(int index) {
    setState(() {
      selectedMenuIndex = index;
      Navigator.pop(context); // Đóng Drawer sau khi chọn
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.blue,
      ),
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
                onTap: () => onSelectMenu(0)),
            ListTile(
                leading: Icon(Icons.people),
                title: Text('Bệnh nhân'),
                onTap: () => onSelectMenu(1)),
            ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Lịch hẹn'),
                onTap: () => onSelectMenu(2)),
            ListTile(
                leading: Icon(Icons.person),
                title: Text('Bác sĩ'),
                onTap: () => onSelectMenu(3)),
            ListTile(
                leading: Icon(Icons.medical_services),
                title: Text('Nhân viên'),
                onTap: () => onSelectMenu(4)),
            ListTile(
                leading: Icon(Icons.add_business_sharp),
                title: Text('Quản lý thuốc và kho'),
                onTap: () => onSelectMenu(5)),
            ListTile(
                leading: Icon(Icons.bar_chart_sharp),
                title: Text('Báo cáo và Thống kê'),
                onTap: () => onSelectMenu(6)),
            ListTile(
                leading: Icon(Icons.business),
                title: Text('Quản lý phòng ban'),
                onTap: () => onSelectMenu(7)),
            ListTile(
                leading: Icon(Icons.security_sharp),
                title: Text('Bảo mật và Phân quyền'),
                onTap: () => onSelectMenu(8)),
            ListTile(
                leading: Icon(Icons.logout),
                title: Text('Đăng xuất'),
                onTap: () {}),
          ],
        ),
      ),
      body: pages[selectedMenuIndex],
    );
  }
}
