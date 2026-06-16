import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/receptionist_provider.dart';
import '../../services/socket_service.dart';

const kPrimaryColor = Color(0xFF0D47A1); // Deep Indigo
const kSecondaryColor = Color(0xFF1976D2);
const kAccentColor = Color(0xFF4CAF50); // Emerald Green
const kBackgroundColor = Color(0xFFF5F7FA);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF333333);

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
    // Fetch today's appointments on screen initialization
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
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    // Calculate real stats dynamically from the state's loaded appointments
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
            },
          )
        ],
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Tổng quan",
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Xin chào, Lễ tân",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Hôm nay: ${DateFormat('dd/MM/yyyy').format(state.selectedDate)}",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Real-time Overview Cards
                  _buildOverviewCards(totalPatients, waiting, checkedIn, completed, formattedRevenue),
                  const SizedBox(height: 24),

                  // Quick Actions Card Section
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Charts Section using dynamic data aggregation
                  _buildChartsSection(state.appointments),
                  const SizedBox(height: 24),

                  // Real-time Live Queue list
                  _buildRecentAppointments(state.appointments),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards(int total, int wait, int checkedIn, int done, String revStr) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("Bệnh nhân hôm nay", total.toString(), Icons.group, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard("Chờ Check-in", wait.toString(), Icons.hourglass_top, Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard("Đang trong hàng chờ", checkedIn.toString(), Icons.check_circle_outline, Colors.green),
            const SizedBox(width: 16),
            _buildStatCard("Đã khám xong", done.toString(), Icons.done_all, Colors.teal),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard("Doanh thu thực tế (Đã thu)", revStr, Icons.monetization_on, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thao tác nhanh",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionItem(Icons.list_alt, "Check-in Lịch hẹn", () {
                context.go('/receptionist/appointment-management');
              }),
              _buildActionItem(Icons.description, "Hồ sơ bệnh án", () {
                context.go('/receptionist/medical-records');
              }),
              _buildActionItem(Icons.people_outline, "Quản lý bệnh nhân", () {
                context.go('/receptionist/patient-management');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: kSecondaryColor.withOpacity(0.08),
              child: Icon(icon, size: 26, color: kSecondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(List<dynamic> appointments) {
    return Column(
      children: [
        _buildChartContainer("Lưu lượng bệnh nhân theo buổi", _buildPatientBarChart(appointments)),
        const SizedBox(height: 24),
        _buildChartContainer("Cơ cấu chuyên khoa khám hôm nay", _buildSpecialtyPieChart(appointments)),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildPatientBarChart(List<dynamic> appointments) {
    // Group appointments into morning (before 12 PM) vs afternoon/evening (after 12 PM)
    int morningCount = 0;
    int afternoonCount = 0;

    for (var appt in appointments) {
      final timeStr = appt.time.toString().toLowerCase();
      // Simple parse check: if it contains 'am' or hour is early (e.g. 07:00, 08:00, 09:00, 10:00, 11:00)
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
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (maxVal / 4).roundToDouble().clamp(1.0, 50.0)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold);
                String text = '';
                if (value.toInt() == 0) text = 'Sáng (AM)';
                if (value.toInt() == 1) text = 'Chiều (PM)';
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: morningCount.toDouble(), color: Colors.orange, width: 32, borderRadius: BorderRadius.circular(4))
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: afternoonCount.toDouble(), color: Colors.blue, width: 32, borderRadius: BorderRadius.circular(4))
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
      return const Center(child: Text("Không có lịch hẹn để lập sơ đồ cơ cấu"));
    }

    final total = specialtyMap.values.fold(0, (sum, val) => sum + val);
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];

    int index = 0;
    final sections = specialtyMap.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${percent.toStringAsFixed(0)}%)',
        radius: 70,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 35,
        sections: sections,
      ),
    );
  }

  Widget _buildRecentAppointments(List<dynamic> appointments) {
    final recent = appointments.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lịch khám ngày hôm nay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              TextButton(
                onPressed: () => context.go('/receptionist/appointment-management'),
                child: const Text("Xem tất cả"),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 8),
                    Text("Không có lịch khám nào cho hôm nay", style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final appt = recent[index];
                Color statusColor = Colors.grey;
                String statusLabel = appt.status;
                switch (appt.status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    statusLabel = 'Chờ xác nhận';
                    break;
                  case 'confirmed':
                    statusColor = Colors.blue;
                    statusLabel = 'Đã xác nhận';
                    break;
                  case 'checked_in':
                    statusColor = Colors.green;
                    statusLabel = 'Đã Check-in';
                    break;
                  case 'completed':
                    statusColor = Colors.teal;
                    statusLabel = 'Hoàn thành';
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusLabel = 'Đã hủy';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            appt.time,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF222222)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Bác sĩ: ${appt.doctorName} • ${appt.departmentName}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}