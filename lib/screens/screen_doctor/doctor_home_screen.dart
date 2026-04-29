import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm intl để format ngày tháng
import 'package:shared_preferences/shared_preferences.dart';
// Import các màn hình con (Giữ nguyên)
import 'appointment_page.dart';
import 'prescription.dart';
import 'patient_management.dart';
import 'classification_results.dart';
import 'consultation.dart';
import 'progress_tracking.dart';
import 'statistics.dart';

// --- PALETTE MÀU Y TẾ HIỆN ĐẠI ---
const Color kPrimaryColor = Color(0xFF009688); // blue đậm
const Color kSecondaryColor = Color(0xFFB2DFDB); // blue nhạt
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextDark = Color(0xFF263238);

void main() => runApp(DoctorApp());

class DoctorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: kBackgroundColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // Font chữ tiêu chuẩn
      ),
      home: DoctorDashboard(),
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final List<_DashboardItem> items = [
    _DashboardItem("Lịch Hẹn", Icons.calendar_month_rounded, Colors.blue,
        AppointmentPage()),
    _DashboardItem(
        "Kê Đơn", Icons.medication_rounded, Colors.green, PrescriptionPage()),
    _DashboardItem("Bệnh Nhân", Icons.people_alt_rounded, Colors.orange,
        PatientManagementPage()),
    _DashboardItem("Kết Quả", Icons.analytics_rounded, Colors.purple,
        ClassificationResultsPage()),
    _DashboardItem(
        "Tư Vấn", Icons.chat_bubble_rounded, Colors.pink, ConsultationPage()),
    _DashboardItem("Tiến Trình", Icons.timeline_rounded, Colors.blue,
        ProgressTrackingPage()),
    // _DashboardItem("Báo Cáo", Icons.pie_chart_rounded, Colors.indigo, StatisticsPage()), // Có thể ẩn bớt nếu quá nhiều
  ];

  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var formattedDate = DateFormat('EEEE, d MMMM', 'vi')
        .format(now); // Cần setup locale tiếng Việt nếu muốn

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar ẩn để tự làm Header đẹp hơn

      drawer: _buildDrawer(context), // Drawer giữ nguyên hoặc tùy chỉnh

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER CHÀO MỪNG
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Xin chào,",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600])),
                      Text("Dr. Hanh 👋",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kTextDark)),
                    ],
                  ),
                  Builder(
                    // Builder để mở Drawer
                    builder: (context) => InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(
                            'assets/doctor_avatar.png'), // Thay bằng ảnh thật
                        child:
                            Icon(Icons.person, color: Colors.white), // Fallback
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 20),

              // 2. THỐNG KÊ NHANH (STAT CARDS)
              Container(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatCard("Bệnh nhân chờ", "12", Icons.hourglass_top,
                        Colors.orange),
                    _buildStatCard(
                        "Đã khám xong", "28", Icons.check_circle, Colors.green),
                    _buildStatCard("Tổng lịch hẹn", "40", Icons.calendar_today,
                        Colors.blue),
                  ],
                ),
              ),
              SizedBox(height: 25),

              // 3. LỊCH TRÌNH SẮP TỚI (DASHBOARD WIDGET)
              Text("Lịch Trình Hôm Nay",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              SizedBox(height: 10),
              _buildUpcomingAppointmentCard(),
              SizedBox(height: 25),

              // 4. MENU CHỨC NĂNG (GRID)
              Text("Chức Năng Quản Lý",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cột
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1, // Tỉ lệ khung hình thẻ
                ),
                itemBuilder: (context, index) {
                  return _buildMenuCard(items[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // --- WIDGET CON: DRAWER ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("Dr. Hạnh",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text("Khoa Nội Tổng Quát"),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: kPrimaryColor)),
            decoration: BoxDecoration(color: kPrimaryColor),
          ),
          ListTile(
              leading: Icon(Icons.settings),
              title: Text("Cài đặt"),
              onTap: () {}),
          ListTile(
              leading: Icon(Icons.help), title: Text("Trợ giúp"), onTap: () {}),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          )
        ],
      ),
    );
  }

  // --- WIDGET CON: THẺ THỐNG KÊ ---
  // --- WIDGET CON: THẺ THỐNG KÊ (ĐÃ SỬA LỖI OVERFLOW) ---
  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 15),
      padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12), // ✅ Giảm padding: all(15) -> vertical(12)
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8), // ✅ Giảm khoảng cách: 10 -> 8
          Text(count,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4), // ✅ Thêm khoảng cách nhỏ
          // ✅ Sử dụng TextOverflow để tránh tràn chữ nếu tiêu đề quá dài
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- WIDGET CON: LỊCH HẸN SẮP TỚI ---
  Widget _buildUpcomingAppointmentCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kPrimaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15)),
            child:
                Icon(Icons.access_time_filled, color: Colors.white, size: 30),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tiếp theo: 10:30 AM",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("Nguyễn Văn An",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text("Khám tổng quát • P.102",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  // --- WIDGET CON: THẺ MENU CHỨC NĂNG ---
  Widget _buildMenuCard(_DashboardItem item) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => item.page)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 32, color: item.color),
            ),
            SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;

  final Color color; // Thêm màu sắc riêng cho từng item
  final Widget page;

  _DashboardItem(this.title, this.icon, this.color, this.page);
}
