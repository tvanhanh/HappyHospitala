import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/receptionist_provider.dart';
import '../../services/socket_service.dart';
import 'messenger_screen.dart';

// Hệ màu cao cấp chuẩn Clinic SaaS mới
const Color kPrimaryColor = Color(0xFF0F172A); // Màu tối sang trọng thay cho xanh đậm cổ điển
const Color kSecondaryColor = Color(0xFF2563EB); // Royal Blue hiện đại
const Color kAccentColor = Color(0xFF10B981); // Emerald Green tinh tế
const Color kBackgroundColor = Color(0xFFF8FAFC); 
const Color kCardColor = Colors.white;
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextColor = Color(0xFF1E293B);

class ReceptionistDashboard extends ConsumerStatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  ConsumerState<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends ConsumerState<ReceptionistDashboard> {
  Function(dynamic)? _notificationCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = ref.read(receptionistProvider).selectedDate;
      ref.read(receptionistProvider.notifier).fetchAppointments(selectedDate);
    });

    _notificationCallback = (data) {
      if (mounted) {
        final Map<String, dynamic> notification = Map<String, dynamic>.from(data);
        final title = notification['title'] ?? 'Thông báo';
        final body = notification['body'] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 5),
          ),
        );
        final selectedDate = ref.read(receptionistProvider).selectedDate;
        ref.read(receptionistProvider.notifier).fetchAppointments(selectedDate);
      }
    };
    SocketService.instance.on(SocketEvents.newNotification, _notificationCallback!);
  }

  @override
  void dispose() {
    if (_notificationCallback != null) {
      SocketService.instance.off(SocketEvents.newNotification, _notificationCallback);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receptionistProvider);

    final totalPatients = state.appointments.map((a) => a.patientId).toSet().length;
    final waiting = state.appointments.where((a) => ['pending', 'confirmed'].contains(a.status)).length;
    final checkedIn = state.appointments.where((a) => a.status == 'checked_in').length;
    final completed = state.appointments.where((a) => a.status == 'completed').length;
    final revenue = state.appointments
        .where((a) => a.isPaid || a.status == 'completed')
        .fold(0.0, (sum, a) => sum + a.finalFee);

    final formattedRevenue = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(revenue);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Happy Clinic - Hệ thống quản lý",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: kBorderColor, height: 1),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Tổng quan",
      ),
      
      // NÚT CHAT MESSENGER NỔI CHUYÊN NGHIỆP TRÊN GIAO DIỆN
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
        Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReceptionistMessengerScreen()),
    ); // Điều hướng tới trang chat hỗ trợ của bạn
        },
        backgroundColor: kSecondaryColor,
        elevation: 4,
        icon: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
        label: const Text(
          "Hỗ trợ khách hàng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Khối Nội Dung Chính
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Header tinh gọn
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Xin chào, Lễ tân",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Hôm nay: ${DateFormat('dd/MM/yyyy').format(state.selectedDate)}",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Thống kê phân chia dạng lưới gọn gàng
                          _buildOverviewGrid(totalPatients, waiting, checkedIn, completed, formattedRevenue),
                          const SizedBox(height: 24),

                          // Hành động nhanh dạng nút bấm cao cấp
                          _buildQuickActions(context),
                          const SizedBox(height: 24),

                          // Đồ thị trực quan
                          _buildChartsSection(state.appointments),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Khối Hàng Chờ Trực Quan Bên Phải (Layout Dashboard Tiêu chuẩn)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: _buildLiveQueueSection(state.appointments),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewGrid(int total, int wait, int checkedIn, int done, String revStr) {
    return Column(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard("Bệnh nhân hôm nay", total.toString(), Icons.group_outlined, Colors.blue),
            _buildStatCard("Chờ Check-in", wait.toString(), Icons.hourglass_top_rounded, Colors.orange),
            _buildStatCard("Trong hàng chờ", checkedIn.toString(), Icons.directions_run_rounded, kSecondaryColor),
            _buildStatCard("Đã khám xong", done.toString(), Icons.check_circle_outline_rounded, kAccentColor),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                radius: 22,
                child: const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DOANH THU THỰC TẾ (ĐÃ THU)",
                    style: TextStyle(color: const Color.fromARGB(255, 80, 156, 183), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    revStr,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thao tác nhanh hệ thống",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(Icons.assignment_turned_in_outlined, "Check-in Lịch hẹn", () {
                context.go('/receptionist/appointment-management');
              }),
              const SizedBox(width: 12),
              _buildActionButton(Icons.folder_shared_outlined, "Hồ sơ bệnh án", () {
                context.go('/receptionist/medical-records');
              }),
              const SizedBox(width: 12),
              _buildActionButton(Icons.assignment_ind_outlined, "Quản lý bệnh nhân", () {
                context.go('/receptionist/patient-management');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: kSecondaryColor),
        label: Text(label, style: const TextStyle(color: kTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: kBorderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChartsSection(List<dynamic> appointments) {
    return Row(
      children: [
        Expanded(child: _buildChartContainer("Lưu lượng bệnh nhân theo buổi", _buildPatientBarChart(appointments))),
        const SizedBox(width: 16),
        Expanded(child: _buildChartContainer("Cơ cấu chuyên khoa khám", _buildSpecialtyPieChart(appointments))),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildPatientBarChart(List<dynamic> appointments) {
    int morningCount = 0;
    int afternoonCount = 0;

    for (var appt in appointments) {
      final timeStr = appt.time.toString().toLowerCase();
      if (timeStr.contains('am') || timeStr.startsWith('0') || timeStr.startsWith('10') || timeStr.startsWith('11')) {
        morningCount++;
      } else {
        afternoonCount++;
      }
    }

    double maxVal = (morningCount > afternoonCount ? morningCount : afternoonCount).toDouble();
    if (maxVal < 5) maxVal = 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxVal + 2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: (maxVal / 4).roundToDouble().clamp(1.0, 50.0)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500);
                String text = value.toInt() == 0 ? 'Sáng (AM)' : 'Chiều (PM)';
                return SideTitleWidget(meta: meta, child: Text(text, style: style));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: morningCount.toDouble(), color: Colors.orange.shade400, width: 24, borderRadius: BorderRadius.circular(4))
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: afternoonCount.toDouble(), color: kSecondaryColor, width: 24, borderRadius: BorderRadius.circular(4))
          ]),
        ],
      ),
    );
  }

  Widget _buildSpecialtyPieChart(List<dynamic> appointments) {
    final Map<String, int> specialtyMap = {};
    for (var appt in appointments) {
      final spec = appt.departmentName.toString().isNotEmpty ? appt.departmentName.toString() : "Khác";
      specialtyMap[spec] = (specialtyMap[spec] ?? 0) + 1;
    }

    if (specialtyMap.isEmpty) {
      return const Center(child: Text("Không có lịch hẹn hôm nay"));
    }

    final total = specialtyMap.values.fold(0, (sum, val) => sum + val);
    final List<Color> colors = [kSecondaryColor, kAccentColor, Colors.orange, Colors.purple, Colors.teal];

    int index = 0;
    final sections = specialtyMap.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${percent.toStringAsFixed(0)}%)',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: sections,
      ),
    );
  }

  Widget _buildLiveQueueSection(List<dynamic> appointments) {
    final recent = appointments.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lịch khám hôm nay",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: kSecondaryColor),
                onPressed: () => context.go('/receptionist/appointment-management'),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey.shade300, size: 36),
                    const SizedBox(height: 8),
                    Text("Không có lịch khám nào", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 16),
              itemBuilder: (context, index) {
                final appt = recent[index];
                Color statusColor = Colors.grey;
                String statusLabel = appt.status;
                switch (appt.status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    statusLabel = 'Chờ duyệt';
                    break;
                  case 'confirmed':
                    statusColor = Colors.blue;
                    statusLabel = 'Đã duyệt';
                    break;
                  case 'checked_in':
                    statusColor = kSecondaryColor;
                    statusLabel = 'Đang chờ khám';
                    break;
                  case 'completed':
                    statusColor = kAccentColor;
                    statusLabel = 'Hoàn thành';
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusLabel = 'Đã hủy';
                    break;
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Text(
                        appt.time,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "BS. ${appt.doctorName} • ${appt.departmentName}",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                );
              },
            )
        ],
      ),
    );
  }
}