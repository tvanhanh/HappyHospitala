import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_chart/fl_chart.dart';

// Import providers
import '../../providers/admin_stats_provider.dart';

// Import screens
import 'appointment_managemet.dart';
import 'account_manager_screen.dart';
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
// --- PALETTE MÀU SẮC HIỆN ĐẠI ---
const Color _kPrimary = Color(0xFF1565C0);
const Color _kPrimaryDark = Color(0xFF0D47A1);
const Color _kAccent = Color(0xFF00B0FF);
const Color _kBackground = Color(0xFFF4F7FA);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    _DashboardStatsView(onNavigate: _navigateToTab),
    const AccountManagerScreen(),
    const DoctorListScreen(),
    const SpecialtyManagerScreen(),
    const RoomManagerScreen(),
    AdminAppointmentsScreen(),
    const AdminSliderManagerScreen(),
    const PromotionManagerScreen(),
    const PremiumPackageScreen(),
    const AdvertisementScreen(),
    const SalaryManagerScreen(),
    const RevenueReportScreen(),
    const StaffManagerScreen(),
    PatientListScreen(),
    MedicineInventory(),
    const ManagePriceScreen(),
    MonthlyReportScreen(),
    UserManagementScreen(),
    const MedicalRecordsScreen(showAppBar: false, showDrawer: false),
  ];

  final List<String> _titles = [
    'Tổng Quan Thống Kê',
    'Quản Lý Tài Khoản',
    'Quản Lý Bác Sĩ',
    'Quản Lý Chuyên Khoa',
    'Quản Lý Phòng Khám',
    'Lịch Hẹn',
    'Banner Slider',
    'Quản Lý Khuyến Mãi',
    'Gói Premium',
    'Quảng Cáo',
    'Lương & Thưởng',
    'Báo Cáo Doanh Thu',
    'Quản Lý Nhân Viên',
    'Quản Lý Bệnh Nhân',
    'Quản Lý Kho Thuốc',
    'Quản Lý Bảng Giá',
    'Báo Cáo Thống Kê',
    'Bảo Mật Hệ Thống',
    'Hồ Sơ Bệnh Án',
  ];

  void _onSelectMenu(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Đóng Drawer
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimaryDark, _kPrimary, _kAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: _kPrimary.withOpacity(0.3),
      ),
      drawer: Drawer(
        elevation: 10,
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                children: [
                  _buildSectionTitle("DASHBOARD"),
                  _buildDrawerItem(0, Icons.dashboard_rounded, 'Bảng Điều Khiển'),
                  _buildSectionTitle("NHÂN SỰ & NGƯỜI DÙNG"),
                  _buildDrawerItem(1, Icons.manage_accounts_rounded, 'Quản Lý Tài Khoản'),
                  _buildDrawerItem(12, Icons.badge_rounded, 'Quản Lý Nhân Viên'),
                  _buildDrawerItem(2, Icons.medical_information_rounded, 'Quản Lý Bác Sĩ (Duyệt)'),
                  _buildDrawerItem(13, Icons.people_outline_rounded, 'Quản Lý Bệnh Nhân'),
                  _buildDrawerItem(10, Icons.monetization_on_rounded, 'Lương & Thưởng'),
                  const SizedBox(height: 15),
                  
                  _buildSectionTitle("CƠ SỞ VẬT CHẤT & KHÁM"),
                  _buildDrawerItem(3, Icons.local_hospital_rounded, 'Chuyên Khoa'),
                  _buildDrawerItem(4, Icons.meeting_room_rounded, 'Phòng Khám'),
                  _buildDrawerItem(5, Icons.calendar_month_rounded, 'Lịch Hẹn & Tối Ưu'),
                  _buildDrawerItem(14, Icons.inventory_2_rounded, 'Quản Kho Thuốc, VT'),
                  _buildDrawerItem(15, Icons.price_change_rounded, 'Quản Lý Bảng Giá'),
                  _buildDrawerItem(18, Icons.description_rounded, 'Hồ sơ bệnh án'),
                  const SizedBox(height: 15),

                  _buildSectionTitle("MARKETING & DỊCH VỤ"),
                  _buildDrawerItem(6, Icons.view_carousel_rounded, 'Banner Slider'),
                  _buildDrawerItem(7, Icons.discount_rounded, 'Khuyến Mãi'),
                  _buildDrawerItem(8, Icons.workspace_premium_rounded, 'Gói Premium'),
                  _buildDrawerItem(9, Icons.campaign_rounded, 'Quảng Cáo'),
                  const SizedBox(height: 15),

                  _buildSectionTitle("TÀI CHÍNH & HỆ THỐNG"),
                  _buildDrawerItem(11, Icons.bar_chart_rounded, 'Báo Cáo Doanh Thu'),
                  _buildDrawerItem(16, Icons.pie_chart_rounded, 'Báo Cáo Thống Kê'),
                  _buildDrawerItem(17, Icons.security_rounded, 'Bảo Mật Hệ Thống'),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryDark, _kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.admin_panel_settings_rounded, size: 34, color: _kPrimaryDark),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("QUẢN TRỊ VIÊN", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
                Text("Smart Clinic", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Bảng Điều Khiển Cấp Cao", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 5),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [_kPrimary.withOpacity(0.15), _kPrimary.withOpacity(0.05)])
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _kPrimary.withOpacity(0.5) : Colors.transparent),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: isSelected ? _kPrimary : Colors.grey.shade600, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? _kPrimaryDark : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kPrimary) : null,
        onTap: () => _onSelectMenu(index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// --- DASHBOARD THỐNG KÊ (REAL DATA) ---
// ---------------------------------------------------------------------------

class _DashboardStatsView extends ConsumerWidget {
  final Function(int) onNavigate;
  const _DashboardStatsView({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(adminStatsProvider);

    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Không thể tải thống kê: $err', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(adminStatsProvider),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chỉ số Hoạt động',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _StatCard(
                    title: 'Bác Sĩ',
                    value: stats.totalDoctors.toString(),
                    icon: Icons.medical_information,
                    color: const Color(0xFF1565C0),
                    onTap: () => onNavigate(2),
                  ),
                  _StatCard(
                    title: 'Bệnh Nhân',
                    value: stats.totalPatients.toString(),
                    icon: Icons.people_outline,
                    color: const Color(0xFF00897B),
                    onTap: () => onNavigate(13),
                  ),
                  _StatCard(
                    title: 'Lịch Hẹn',
                    value: stats.totalAppointments.toString(),
                    icon: Icons.calendar_month,
                    color: const Color(0xFFF57C00),
                    onTap: () => onNavigate(5),
                  ),
                  _StatCard(
                    title: 'Chuyên Khoa',
                    value: stats.totalSpecialties.toString(),
                    icon: Icons.local_hospital,
                    color: const Color(0xFF7B1FA2),
                    onTap: () => onNavigate(3),
                  ),
                  _StatCard(
                    title: 'Phòng Khám',
                    value: stats.totalRooms.toString(),
                    icon: Icons.meeting_room,
                    color: const Color(0xFFD32F2F),
                    onTap: () => onNavigate(4),
                  ),
                  _StatCard(
                    title: 'Doanh Thu',
                    value: '1.2B ₫', // Placeholder for real API data
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFFE65100),
                    onTap: () => onNavigate(11),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- CHARTS SECTION ---
              const Text(
                'Biểu Đồ & Phân Tích',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRevenueChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildAppointmentPieChart()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildRevenueChart(),
                        const SizedBox(height: 20),
                        _buildAppointmentPieChart(),
                      ],
                    );
                  }
                },
              ),
              
              const SizedBox(height: 40),
              
              // --- BIỂU ĐỒ BAR CHART (fl_chart) ---
              const Text(
                'Phân Bố Bác Sĩ Theo Chuyên Khoa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              _buildChartSection(ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection(WidgetRef ref) {
    final asyncChartData = ref.watch(chartDataProvider);
    
    return asyncChartData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Lỗi tải dữ liệu biểu đồ: $err')),
      data: (chartData) {
        if (chartData.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu biểu đồ'));
        }

        // Generate BarChartGroupData
        List<BarChartGroupData> barGroups = [];
        double maxY = 0;

        for (int i = 0; i < chartData.length; i++) {
          final data = chartData[i];
          if (data.count > maxY) maxY = data.count.toDouble();
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data.count.toDouble(),
                  color: _kAccent,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
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
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartData.length) return const SizedBox.shrink();
                      
                      final name = chartData[index].name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          name.length > 10 ? '${name.substring(0, 8)}..' : name,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        );
      },
    );
  }

  // --- REVENUE LINE CHART ---
  Widget _buildRevenueChart() {
    // DUMMY DATA FOR REVENUE
    final spots = const [
      FlSpot(1, 10),
      FlSpot(2, 25),
      FlSpot(3, 18),
      FlSpot(4, 40),
      FlSpot(5, 55),
      FlSpot(6, 50),
      FlSpot(7, 80),
    ];

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kPrimary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Doanh Thu 7 Ngày Qua (Triệu VNĐ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1, dashArray: [5, 5])),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('T${value.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}M', style: const TextStyle(fontSize: 12, color: Colors.grey));
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _kPrimary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _kPrimary.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- APPOINTMENT PIE CHART ---
  Widget _buildAppointmentPieChart() {
    // DUMMY DATA FOR PIE CHART
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kPrimary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Trạng Thái Lịch Hẹn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue.shade400,
                    value: 40,
                    title: '40%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.green.shade400,
                    value: 30,
                    title: '30%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.orange.shade400,
                    value: 15,
                    title: '15%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.red.shade400,
                    value: 15,
                    title: '15%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildLegend(Colors.blue.shade400, "Chờ duyệt"),
              _buildLegend(Colors.green.shade400, "Hoàn thành"),
              _buildLegend(Colors.orange.shade400, "Đang khám"),
              _buildLegend(Colors.red.shade400, "Hủy"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovering = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) {
          setState(() => _isTapped = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: _isTapped ? 0.95 : (_isHovering ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withValues(alpha: _isHovering ? 0.9 : 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _isHovering ? 0.6 : 0.4),
                  blurRadius: _isHovering ? 16 : 12,
                  offset: Offset(0, _isHovering ? 8 : 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: AnimatedOpacity(
                    opacity: _isHovering ? 0.4 : 0.2,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(widget.icon, size: 80, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
