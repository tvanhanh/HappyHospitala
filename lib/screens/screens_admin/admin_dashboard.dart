import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

// Import providers
import '../../providers/admin_stats_provider.dart';

// Import screens (Giữ nguyên các import của bạn)
import 'appointment_management.dart';
import 'specialty_manager_screen.dart';
import 'room_manager_screen.dart';
import 'doctor_list.dart';
import 'slider_manager_screen.dart';
import 'promotion_manager_screen.dart';
import 'premium_package_screen.dart';
import 'advertisement_screen.dart';
import 'salary_manager_screen.dart';
import 'revenue_report_screen.dart';
import 'staff_manager_screen.dart';
import 'patient_list.dart';
import 'inventory_management.dart';
import 'manage_price.dart';
import 'report_statistics.dart';
import 'security_screens/security_ayth.dart';
import '../screen_receptionist/medical_records_screen.dart';

import '../screens_admin/supplier/add_supplier_page.dart';


// --- PALETTE 2026 (SMART CLINIC & AI/BLOCKCHAIN THEME) ---
const Color kWebBg = Color(0xFFF1F5F9); // Slate 100
const Color kSurface = Colors.white;
const Color kBorder = Color(0xFFE2E8F0); // Slate 200
const Color kTextMain = Color(0xFF0F172A); // Slate 900
const Color kTextSub = Color(0xFF64748B); // Slate 500
const Color kPrimary = Color(0xFF2563EB); // Blue 600
const Color kPrimaryDark = Color(0xFF1E3A8A); // Blue 900
const Color kAccentAI = Color(0xFF8B5CF6); // Purple (AI Prediction)
const Color kAccentBlockchain = Color(0xFF10B981); // Emerald (Secure EMR)
const Color kWarning = Color(0xFFF59E0B); // Amber 500


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
  // --- DASHBOARD ---
  _DashboardStatsView(onNavigate: _navigateToTab), // 0

  // --- NHÂN SỰ & NGƯỜI DÙNG ---
  UserManagementScreen(), // 1 (Đổi từ DoctorListScreen thành Quản lý tài khoản)
  const StaffManagerScreen(), // 2
  const DoctorListScreen(), // 3
  const PatientListScreen(), // 4
  const SalaryManagerScreen(), // 5

  // --- CƠ SỞ VẬT CHẤT & KHÁM ---
  const SpecialtyManagerScreen(), // 6
  const RoomManagerScreen(), // 7
  const AdminAppointmentsScreen(), // 8
  MedicineInventory(), // 9
  const AddSupplierPage(), // 10
  const ManagePriceScreen(), // 11
  const MedicalRecordsScreen(showAppBar: false, showDrawer: false), // 12

  // --- MARKETING & DỊCH VỤ ---
  const AdminSliderManagerScreen(), // 13
  const PromotionManagerScreen(), // 14
  const PremiumPackageScreen(), // 15
  const AdvertisementScreen(), // 16

  // --- TÀI CHÍNH & BẢO MẬT ---
  const RevenueReportScreen(), // 17
  MonthlyReportScreen(), // 18
  const Placeholder(), // 19 - Thêm widget tạm thời cho trang Bảo mật hệ thống/Blockchain (bạn có thể thay bằng screen tương ứng)
];

  final List<String> _titles = [
  // --- DASHBOARD ---
  'Tổng Quan Hệ Thống', // 0

  // --- NHÂN SỰ & NGƯỜI DÙNG ---
  'Quản Lý Tài Khoản', // 1
  'Quản Lý Nhân Viên', // 2
  'Quản Lý Bác Sĩ', // 3
  'Quản Lý Bệnh Nhân', // 4
  'Lương & Thưởng', // 5

  // --- CƠ SỞ VẬT CHẤT & KHÁM ---
  'Quản Lý Chuyên Khoa', // 6
  'Quản Lý Phòng Khám', // 7
  'Lịch Hẹn', // 8
  'Quản Lý Kho Thuốc', // 9
  'Nhà cung cấp', // 10
  'Quản Lý Bảng Giá', // 11
  'Hồ Sơ Bệnh Án', // 12

  // --- MARKETING & DỊCH VỤ ---
  'Banner Slider', // 13
  'Quản Lý Khuyến Mãi', // 14
  'Gói Premium', // 15
  'Quảng Cáo', // 16

  // --- TÀI CHÍNH & BẢO MẬT ---
  'Báo Cáo Doanh Thu', // 17
  'Báo Cáo Thống Kê', // 18
  'Bảo Mật Hệ Thống', // 19
];

  void _onSelectMenu(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Đóng Drawer trên màn hình nhỏ
  }

  void _navigateToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kWebBg,
    appBar: AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      shape: const Border(bottom: BorderSide(color: kBorder, width: 1)),
      iconTheme: const IconThemeData(color: kTextMain),
      title: Text(
        _titles[_selectedIndex],
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: kTextMain, fontSize: 18),
      ),
      actions: [
        // --- CHỈ GIỮ LẠI BADGE BLOCKCHAIN TRẠNG THÁI GỌN GÀNG ---
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: kAccentBlockchain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccentBlockchain.withOpacity(0.3))),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Đảm bảo row không chiếm hết màn hình
              children: [
                Icon(Icons.shield, color: kAccentBlockchain, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Blockchain Active",
                  style: TextStyle(
                      color: kAccentBlockchain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {}),
        const SizedBox(width: 16),
      ],
    ),
    // Drawer này sẽ hoạt động hoàn hảo khi bấm vào nút menu 3 gạch trên AppBar
    drawer: _buildModernDrawer(), 
    body: _pages[_selectedIndex],
  );
}
  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: kPrimaryDark, // Nền Dark Blue
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.hub_outlined,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Smart Clinic",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Quản trị hệ thống",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 12), // Giảm padding ngang một chút
              physics: const BouncingScrollPhysics(),
             children: [
  _buildSectionTitle("DASHBOARD"),
  _buildDrawerItem(0, Icons.dashboard_rounded, 'Bảng Điều Khiển'),
  
  _buildSectionTitle("NHÂN SỰ & NGƯỜI DÙNG"),
  _buildDrawerItem(1, Icons.manage_accounts_rounded, 'Quản Lý Tài Khoản'),
  _buildDrawerItem(2, Icons.badge_rounded, 'Quản Lý Nhân Viên'),
  _buildDrawerItem(3, Icons.medical_information_rounded, 'Quản Lý Bác Sĩ'),
  _buildDrawerItem(4, Icons.people_outline_rounded, 'Quản Lý Bệnh Nhân'),
  _buildDrawerItem(5, Icons.monetization_on_rounded, 'Lương & Thưởng'),
  
  _buildSectionTitle("CƠ SỞ VẬT CHẤT & KHÁM"),
  _buildDrawerItem(6, Icons.local_hospital_rounded, 'Chuyên Khoa'),
  _buildDrawerItem(7, Icons.meeting_room_rounded, 'Phòng Khám'),
  _buildDrawerItem(8, Icons.calendar_month_rounded, 'Lịch Hẹn & Tối Ưu'),
  _buildDrawerItem(9, Icons.inventory_2_rounded, 'Quản Kho Thuốc, VT'),
  _buildDrawerItem(10, Icons.view_list_rounded, 'Nhà cung cấp'),
  _buildDrawerItem(11, Icons.price_change_rounded, 'Bảng Giá Dịch Vụ'),
  _buildDrawerItem(12, Icons.description_rounded, 'Hồ sơ bệnh án (EMR)'),
  
  _buildSectionTitle("MARKETING & DỊCH VỤ"),
  _buildDrawerItem(13, Icons.view_carousel_rounded, 'Banner Slider'),
  _buildDrawerItem(14, Icons.discount_rounded, 'Khuyến Mãi'),
  _buildDrawerItem(15, Icons.workspace_premium_rounded, 'Gói Premium'),
  _buildDrawerItem(16, Icons.campaign_rounded, 'Quảng Cáo'),
  
  _buildSectionTitle("TÀI CHÍNH & BẢO MẬT"),
  _buildDrawerItem(17, Icons.bar_chart_rounded, 'Báo Cáo Doanh Thu'),
  _buildDrawerItem(18, Icons.pie_chart_rounded, 'Báo Cáo Thống Kê'),
  _buildDrawerItem(19, Icons.security_rounded, 'Bảo Mật Blockchain'),
],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: Icon(Icons.logout, size: 18, color: Colors.red.shade300),
              label: Text("Đăng xuất",
                  style: TextStyle(
                      color: Colors.red.shade300, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                // Đổi nút đăng xuất sang tone Đỏ cảnh báo nhưng mờ, rất chuyên nghiệp
                backgroundColor: Colors.red.withOpacity(0.15),
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
      child: Text(
        title,
        style: TextStyle(
            // Đổi sang màu Xanh lơ nhạt, sẽ cực kỳ nổi bật và êm mắt trên nền xanh đen
            color: Colors.blue.shade200,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        // Đổi sang Trắng trong suốt thay vì dùng màu xanh gắt
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.white60, size: 22),
        title: Text(
          title,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14),
        ),
        onTap: () => _onSelectMenu(index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// --- DASHBOARD THỐNG KÊ (REAL DATA + MODERN UI) ---
// ---------------------------------------------------------------------------

class _DashboardStatsView extends ConsumerWidget {
  final Function(int) onNavigate;
  const _DashboardStatsView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(adminStatsProvider);

    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ĐIỂM NHẤN CỦA ĐỒ ÁN: AI & BLOCKCHAIN STATUS ---
              //_buildSystemHealthBanner(),
              //     const SizedBox(height: 32),

              const Text("Tổng Quan Hoạt Động",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextMain)),
              const SizedBox(height: 16),

              // --- CÁC THẺ THỐNG KÊ (GLASS/CLEAN CARD) ---
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1200
                    ? 5
                    : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: [
                  _StatCardPro(
                    title: 'Bác Sĩ',
                    value: stats.totalDoctors.toString(),
                    icon: Icons.medical_information,
                    color: kPrimary,
                    trend: '+2%',
                    onTap: () => onNavigate(2),
                  ),
                  _StatCardPro(
                    title: 'Bệnh Nhân',
                    value: stats.totalPatients.toString(),
                    icon: Icons.people_outline,
                    color: kAccentBlockchain,
                    trend: '+12%',
                    onTap: () => onNavigate(13),
                  ),

                  _StatCardPro(
                    title: 'Lịch Hẹn Mới',
                    value: stats.totalAppointments.toString(),
                    icon: Icons.calendar_month,
                    color: kWarning,
                    trend: '+5%',
                    onTap: () => onNavigate(5),
                  ),
                  _StatCardPro(
                      title: 'Phòng Khám',
                      value: stats.totalRooms.toString(),
                      icon: Icons.meeting_room,
                      color: kAccentAI,
                      onTap: () => onNavigate(4)),
                  // _StatCardPro(
                  //   title: 'Nhân viên',
                  //   value: stats.totalStaffs.toString(),
                  //   icon: Icons.calendar_month,
                  //   color: kWarning,
                  //   trend: '+5%',
                  //   onTap: () => onNavigate(12),
                  // ),
                  // _StatCardPro(
                  //     title: 'Doanh Thu (Tháng)',
                  //     value: '1.2B ₫',
                  //     icon: Icons.monetization_on,
                  //     color: const Color(0xFFEF4444),
                  //     trend: '+8.4%'),
                ],
              ),
              const SizedBox(height: 32),

              // --- CHARTS SECTION ---
              const Text("Phân Tích Dữ Liệu",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextMain)),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRevenueChart()),
                        const SizedBox(width: 20),
                        Expanded(
                            flex: 2, child: _buildAppointmentPieChart(ref)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildRevenueChart(),
                        const SizedBox(height: 20),
                        _buildAppointmentPieChart(ref),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 32),
              const Text("Phân Bố Bác Sĩ Theo Chuyên Khoa",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextMain)),
              const SizedBox(height: 16),
              _buildChartSection(ref),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // // --- WIDGET ĐẶC BIỆT CHO ĐỒ ÁN AI & BLOCKCHAIN ---
  // Widget _buildSystemHealthBanner() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //               color: kSurface,
  //               borderRadius: BorderRadius.circular(16),
  //               border: Border.all(color: kBorder),
  //               boxShadow: [
  //                 BoxShadow(
  //                     color: Colors.black.withOpacity(0.02),
  //                     blurRadius: 10,
  //                     offset: const Offset(0, 4))
  //               ]),
  //           child: Row(
  //             children: [
  //               Container(
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                       color: kAccentAI.withOpacity(0.1),
  //                       shape: BoxShape.circle),
  //                   child: const Icon(Icons.psychology,
  //                       color: kAccentAI, size: 32)),
  //               const SizedBox(width: 16),
  //               const Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   // children: [
  //                   //   Text("Mô hình AI Chẩn Đoán",
  //                   //       style: TextStyle(
  //                   //           color: kTextSub,
  //                   //           fontSize: 13,
  //                   //           fontWeight: FontWeight.w600)),
  //                   //   SizedBox(height: 4),
  //                   //   Text("Độ chính xác: 96.8%",
  //                   //       style: TextStyle(
  //                   //           color: kTextMain,
  //                   //           fontSize: 18,
  //                   //           fontWeight: FontWeight.bold)),
  //                   // ],
  //                 ),
  //               ),
  //               Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                   decoration: BoxDecoration(
  //                       color: Colors.green.shade50,
  //                       borderRadius: BorderRadius.circular(20)),
  //                   child: Text("Online",
  //                       style: TextStyle(
  //                           color: Colors.green.shade700,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold))),
  //             ],
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 20),
  //       Expanded(
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //               color: kSurface,
  //               borderRadius: BorderRadius.circular(16),
  //               border: Border.all(color: kBorder),
  //               boxShadow: [
  //                 BoxShadow(
  //                     color: Colors.black.withOpacity(0.02),
  //                     blurRadius: 10,
  //                     offset: const Offset(0, 4))
  //               ]),
  //           child: Row(
  //             children: [
  //               Container(
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                       color: kAccentBlockchain.withOpacity(0.1),
  //                       shape: BoxShape.circle),
  //                   child: const Icon(Icons.link,
  //                       color: kAccentBlockchain, size: 32)),
  //               const SizedBox(width: 16),
  //               const Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   // children: [
  //                   //   Text("Hệ thống Blockchain EMR",
  //                   //       style: TextStyle(
  //                   //           color: kTextSub,
  //                   //           fontSize: 13,
  //                   //           fontWeight: FontWeight.w600)),
  //                   //   SizedBox(height: 4),
  //                   //   Text("Đã mã hóa: 12,450 Hồ sơ",
  //                   //       style: TextStyle(
  //                   //           color: kTextMain,
  //                   //           fontSize: 18,
  //                   //           fontWeight: FontWeight.bold)),
  //                   // ],
  //                 ),
  //               ),
  //               Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                   decoration: BoxDecoration(
  //                       color: Colors.blue.shade50,
  //                       borderRadius: BorderRadius.circular(20)),
  //                   child: Text("Secured",
  //                       style: TextStyle(
  //                           color: Colors.blue.shade700,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold))),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // --- REVENUE LINE CHART ---
  Widget _buildRevenueChart() {
    final spots = const [
      FlSpot(1, 10),
      FlSpot(2, 25),
      FlSpot(3, 18),
      FlSpot(4, 40),
      FlSpot(5, 55),
      FlSpot(6, 50),
      FlSpot(7, 80)
    ];
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Doanh Thu 7 Ngày Qua",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: kTextMain)),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                        color: kBorder, strokeWidth: 1, dashArray: [5, 5])),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('T${value.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 12, color: kTextSub))))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}M',
                              style: const TextStyle(
                                  fontSize: 12, color: kTextSub)))),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kPrimary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.2),
                              kPrimary.withOpacity(0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentPieChart(WidgetRef ref) {
    final asyncStatusData = ref.watch(appointmentStatusProvider);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Trạng Thái Lịch Hẹn",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: kTextMain)),
          const SizedBox(height: 20),
          Expanded(
            child: asyncStatusData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text('Lỗi: $err',
                      style: const TextStyle(color: Colors.red))),
              data: (data) {
                if (data.isEmpty) {
                  return const Center(child: Text('Chưa có dữ liệu lịch hẹn'));
                }

                // 1. Tính tổng số lượng lịch hẹn
                final totalAppointments =
                    data.fold(0, (sum, item) => sum + item.count);

                // 2. Cấu hình hiển thị dữ liệu trên vòng tròn
                List<PieChartSectionData> getSections() {
                  return data.map((item) {
                    final percentage = (item.count / totalAppointments * 100);
                    final colorInfo = _getStatusStyle(item.name);

                    return PieChartSectionData(
                      color: colorInfo.color,
                      value: item.count.toDouble(),
                      // ĐỔI Ở ĐÂY: Hiển thị "Số ca" trước, "Phần trăm" ở dòng dưới
                      title:
                          '${item.count} ca\n(${percentage.toStringAsFixed(0)}%)',
                      radius:
                          50, // Tăng nhẹ bán kính lát cắt để chứa đủ 2 dòng chữ
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3, // Khoảng cách giữa 2 dòng chữ cho thoáng
                      ),
                    );
                  }).toList();
                }

                return Column(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius:
                              45, // Giảm nhẹ vòng rỗng ở giữa để lấy không gian cho chữ
                          sections: getSections(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 3. Tự động sinh ra ghi chú (Legend) kèm số lượng thật
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: data.map((item) {
                        final style = _getStatusStyle(item.name);
                        // ĐỔI Ở ĐÂY: Hiển thị nhãn kèm số lượng ở danh sách chú thích (VD: Chờ duyệt: 12 ca)
                        return _buildLegend(
                            style.color, '${style.label}: ${item.count} ca');
                      }).toList(),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// --- HÀM HELPER ĐỂ MAP DỮ LIỆU TỪ BACKEND RA MÀU SẮC & CHỮ TIẾNG VIỆT ---
  ({Color color, String label}) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (color: kPrimary, label: 'Chờ xác nhận');

      case 'confirmed':
        return (color: const Color(0xFF3B82F6), label: 'Đã xác nhận');

      case 'checked_in':
        return (color: const Color(0xFF8B5CF6), label: 'Đã check-in');

      case 'in_progress':
        return (color: kWarning, label: 'Đang khám');

      case 'completed':
        return (color: kAccentBlockchain, label: 'Hoàn thành');

      case 'cancelled':
        return (color: const Color(0xFFEF4444), label: 'Đã hủy');

      case 'missed':
        return (color: Colors.grey, label: 'Vắng khám');

      default:
        return (color: Colors.grey.shade400, label: status);
    }
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- BAR CHART ---
  Widget _buildChartSection(WidgetRef ref) {
    final asyncChartData = ref.watch(chartDataProvider);

    return asyncChartData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Lỗi: $err')),
      data: (chartData) {
        if (chartData.isEmpty)
          return const Center(child: Text('Chưa có dữ liệu'));

        List<BarChartGroupData> barGroups = [];
        double maxY = 0;
        for (int i = 0; i < chartData.length; i++) {
          final data = chartData[i];
          if (data.count > maxY) maxY = data.count.toDouble();
          barGroups.add(BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: data.count.toDouble(),
                color: kAccentAI,
                width: 16,
                borderRadius: BorderRadius.circular(4))
          ]));
        }

        return Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + (maxY * 0.2).clamp(1.0, 10.0),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartData.length)
                            return const SizedBox.shrink();
                          final name = chartData[index].name;
                          return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  name.length > 10
                                      ? '${name.substring(0, 8)}..'
                                      : name,
                                  style: const TextStyle(
                                      fontSize: 11, color: kTextSub)));
                        },
                        reservedSize: 40)),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(value.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: kTextSub));
                        })),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: kBorder, strokeWidth: 1, dashArray: [5, 5])),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        );
      },
    );
  }
}

// --- STAT CARD THIẾT KẾ CLEAN SAAS ---
class _StatCardPro extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap; // 1. Thêm cái này

  const _StatCardPro({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap, // 2. Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // 3. Bọc InkWell để tạo hiệu ứng click đẹp
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(trend!,
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kTextMain)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    color: kTextSub,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
