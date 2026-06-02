import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- COLOR ---
const Color kPrimaryColor = Color(0xFF009688);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextDark = Color(0xFF263238);

String doctorName = "";
String specialty = "";

void main() => runApp(DoctorApp());

class DoctorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoctorDashboard(),
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final List<_DashboardItem> items = [
    _DashboardItem("Hồ sơ", Icons.timeline, Colors.blue, "/home/booking"),
    _DashboardItem(
        "Lịch hẹn", Icons.calendar_month, Colors.blue, "/doctor/appointments"),
    _DashboardItem(
        "Kê đơn", Icons.medication, Colors.green, "/doctor/appointments"),
    _DashboardItem("Bệnh nhân", Icons.people, Colors.orange, "/home/booking"),
    _DashboardItem("Dự đoán", Icons.analytics, Colors.purple, "/diagnosis"),
    _DashboardItem("Tư vấn", Icons.chat, Colors.pink, "/home/booking"),
  ];

  @override
  void initState() {
    super.initState();
    loadDoctorFromToken();
  }

  Future<void> loadDoctorFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString("name") ?? "Bác sĩ";
      specialty = prefs.getString("specialty") ?? "Chuyên khoa";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Xin chào,", style: TextStyle(color: Colors.grey)),
                      Text(
                        doctorName,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(specialty),
                    ],
                  ),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: kPrimaryColor,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 20),

              Text(
                "Chức năng quản lý",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 12),

              // ===== GRID FIX RESPONSIVE =====
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

                  return GridView.builder(
                    itemCount: items.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _buildMenuCard(items[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== DRAWER =====
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(doctorName),
            accountEmail: Text("Khoa: $specialty"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: kPrimaryColor),
            ),
            decoration: BoxDecoration(color: kPrimaryColor),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Đăng xuất"),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) context.go('/login');
            },
          )
        ],
      ),
    );
  }

  // ===== MENU CARD =====
  Widget _buildMenuCard(_DashboardItem item) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: item.color.withOpacity(0.15),
              child: Icon(item.icon, color: item.color),
            ),
            SizedBox(height: 10),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== MODEL =====
class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _DashboardItem(this.title, this.icon, this.color, this.route);
}
