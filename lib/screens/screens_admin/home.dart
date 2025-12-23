import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import các màn hình (giữ nguyên)
import 'report_statistics.dart';
import 'patient_list.dart';
import 'security_screens/security_ayth.dart';
import 'appoitment.dart';
import 'overview.dart';
import 'departmenr_screens/department_management.dart';
import 'doctor_list.dart';
import 'inventory_management.dart';
import 'staff_list.dart';
import 'package:go_router/go_router.dart';

// --- PALETTE MÀU SẮC HIỆN ĐẠI (AI & TECH THEME) ---
const Color primaryColor = Color(0xFF1565C0); // Xanh đậm chuyên nghiệp
const Color secondaryColor = Color(0xFF42A5F5); // Xanh sáng
const Color aiAccentColor = Color(0xFFFF8F00); // Cam (Năng lượng, Tối ưu hóa)
const Color blockchainColor = Color(0xFF673AB7); // Tím (Bảo mật, Mã hóa)
const Color surfaceColor = Colors.white;
const Color backgroundColor = Color(0xFFF5F7FA);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedMenuIndex = 0;

  // --- CẤU TRÚC LẠI DANH SÁCH PAGES ---
  // Đưa Lịch hẹn (AI) và Bảo mật (Blockchain) lên đầu để nhấn mạnh đề tài
  final List<Widget> pages = [
    DashboardOverview(), // 0. Tổng quan
    AppointmentListScreen(), // 1. Lịch hẹn & Tối ưu hóa (AI Core)
    UserManagementScreen(), // 2. Bảo mật & Phân quyền (Blockchain Core)
    PatientListScreen(), // 3. Quản lý Bệnh nhân
    DoctorListScreen(), // 4. Quản lý Bác sĩ
    StaffManagement(), // 5. Quản lý Nhân viên
    DepartmentManagement(), // 6. Quản lý Phòng ban
    MedicineInventory(), // 7. Quản lý Thuốc & Kho
    MonthlyReportScreen(), // 8. Báo cáo
  ];

  void onSelectMenu(int index) {
    setState(() {
      selectedMenuIndex = index;
      Navigator.pop(context); // Đóng Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // --- APP BAR ---
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(selectedMenuIndex),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color(0xFF0D47A1)], // Gradient xanh sâu
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
      ),

      // --- DRAWER (MENU BÊN) ---
      drawer: Drawer(
        elevation: 10,
        width: 280, // Rộng hơn một chút để thoáng
        child: Column(
          children: [
            // 1. HEADER HIỆN ĐẠI
            _buildDrawerHeader(),

            // 2. DANH SÁCH MENU (Cuộn được)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  _buildSectionTitle("DASHBOARD"),
                  _buildDrawerItem(0, Icons.dashboard_rounded, 'Tổng quan'),

                  SizedBox(height: 15),
                  _buildSectionTitle("CÔNG NGHỆ LÕI (CORE)"),

                  // --- MỤC ĐẶC BIỆT: AI / LỊCH HẸN ---
                  _buildSpecialDrawerItem(
                      index: 1,
                      icon: Icons.auto_graph_rounded,
                      title: 'Lịch hẹn & AI Tối ưu',
                      accent: aiAccentColor),

                  SizedBox(height: 8),

                  // --- MỤC ĐẶC BIỆT: BLOCKCHAIN ---
                  _buildSpecialDrawerItem(
                      index: 2,
                      icon: Icons.security_rounded,
                      title: 'Bảo mật Blockchain',
                      accent: blockchainColor),

                  SizedBox(height: 15),
                  Divider(color: Colors.grey.shade300),
                  _buildSectionTitle("QUẢN LÝ TỔNG HỢP"),

                  _buildDrawerItem(3, Icons.people_outline, 'Bệnh nhân'),
                  _buildDrawerItem(
                      4, Icons.medical_information_outlined, 'Bác sĩ'),
                  _buildDrawerItem(5, Icons.badge_outlined, 'Nhân viên'),
                  _buildDrawerItem(6, Icons.apartment_outlined, 'Phòng ban'),

                  SizedBox(height: 10),
                  _buildSectionTitle("HẬU CẦN & BÁO CÁO"),

                  _buildDrawerItem(7, Icons.inventory_2_outlined, 'Kho thuốc'),
                  _buildDrawerItem(8, Icons.analytics_outlined, 'Thống kê'),
                ],
              ),
            ),

            // 3. FOOTER (ĐĂNG XUẤT)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                color: Colors.grey.shade50,
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.logout_rounded, color: Colors.red),
                ),
                title: Text('Đăng xuất',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),

      body: pages[selectedMenuIndex],
    );
  }

  // ---------------------------------------------------------------------------
  // --- CÁC WIDGET CON (UI COMPONENTS) ---
  // ---------------------------------------------------------------------------

  /// 1. Header của Drawer với Gradient và Info
  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.smart_toy_rounded,
                  size: 36, color: primaryColor), // Icon Robot/AI
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ADMIN",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.5)),
                Text("Smart Clinic",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Container(
                  margin: EdgeInsets.only(top: 5),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text("AI & Blockchain",
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 2. Tiêu đề nhóm nhỏ (Section Title)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0, top: 5.0),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  /// 3. Item Menu Đặc Biệt (Có Animation & Đổ bóng) - Dùng cho AI/Blockchain
  Widget _buildSpecialDrawerItem(
      {required int index,
      required IconData icon,
      required String title,
      required Color accent}) {
    final isSelected = selectedMenuIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.03), // Scale nhẹ khi chọn
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              // Gradient nền khi chọn
              gradient: isSelected
                  ? LinearGradient(colors: [
                      accent.withOpacity(0.15),
                      accent.withOpacity(0.05)
                    ])
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: accent.withOpacity(0.5), width: 1)
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: accent.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ]
                  : [],
            ),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? accent : accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: isSelected ? Colors.white : accent, size: 22),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? accent.withOpacity(0.9)
                      : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: accent)
                  : null,
              onTap: () => onSelectMenu(index),
            ),
          ),
        );
      },
    );
  }

  /// 4. Item Menu Thường
  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = selectedMenuIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon,
            color: isSelected ? primaryColor : Colors.grey.shade600, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => onSelectMenu(index),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Tổng Quan Hệ Thống';
      case 1:
        return 'Tối Ưu Hóa Vận Hành (AI)';
      case 2:
        return 'Bảo Mật Dữ Liệu (Blockchain)';
      case 3:
        return 'Danh Sách Bệnh Nhân';
      case 4:
        return 'Đội Ngũ Bác Sĩ';
      case 5:
        return 'Quản Lý Nhân Viên';
      case 6:
        return 'Cơ Cấu Phòng Ban';
      case 7:
        return 'Kho Thuốc & Vật Tư';
      case 8:
        return 'Báo Cáo & Thống Kê';
      default:
        return 'Admin Dashboard';
    }
  }

  void _handleLogout() async {
    // 1. Xóa token trong bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // 2. Điều hướng về trang Login hoặc Home
    if (mounted) {
      // GoRouter.go() tự động xóa sạch Stack lịch sử cho bạn
      // Người dùng sẽ không thể bấm Back để quay lại trang trước đó
      context.go('/login');
    }
  }
}
