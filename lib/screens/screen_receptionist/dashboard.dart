import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/receptionist_provider.dart';
import '../../services/socket_service.dart';
import 'messenger_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';

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
  String _receptionistName = "Lễ tân";

  // Scheduler & detail variables
  String _schedulerViewMode = "day"; // "day", "week", "month"
  List<Appointment> _allAppointments = [];
  bool _loadingAll = false;
  Appointment? _selectedAppointment;

  @override
  void initState() {
    super.initState();
    _loadReceptionistName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = ref.read(receptionistProvider).selectedDate;
      ref.read(receptionistProvider.notifier).fetchAppointments(selectedDate);
      _loadAllAppointments();
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
        _loadAllAppointments();
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

  Future<void> _loadReceptionistName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _receptionistName = prefs.getString("name") ?? "Lễ tân";
      });
    }
  }

  Future<void> _loadAllAppointments() async {
    if (!mounted) return;
    setState(() {
      _loadingAll = true;
    });
    try {
      final list = await AppointmentApi.getAllAppointments();
      if (mounted) {
        setState(() {
          _allAppointments = list;
          _loadingAll = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAll = false;
        });
      }
    }
  }

  // Visual status helpers
  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFFF3E0); // light orange
      case 'confirmed': return const Color(0xFFE3F2FD); // light blue
      case 'checked_in': return const Color(0xFFE8F5E9); // light green
      case 'in_progress': return const Color(0xFFF3E5F5); // light purple
      case 'completed': return const Color(0xFFE0F2F1); // light teal
      case 'cancelled': return const Color(0xFFFFEBEE); // light red
      default: return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFE65100);
      case 'confirmed': return const Color(0xFF0D47A1);
      case 'checked_in': return const Color(0xFF2E7D32);
      case 'in_progress': return const Color(0xFF7B1FA2);
      case 'completed': return const Color(0xFF00695C);
      case 'cancelled': return const Color(0xFFC62828);
      default: return const Color(0xFF616161);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'checked_in': return 'Đã Check-in';
      case 'in_progress': return 'Đang khám';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return 'Không rõ';
    }
  }

  void _selectAppointment(Appointment appt) {
    setState(() {
      _selectedAppointment = appt;
    });
    
    // Check if tablet/mobile view
    final width = MediaQuery.of(context).size.width;
    if (width < 1000) {
      _showDetailDialog(appt);
    }
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
              _loadAllAppointments();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Tổng quan",
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReceptionistMessengerScreen()),
          );
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
          : SelectionArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1000;
                  
                  final mainContent = SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào, $_receptionistName",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Hôm nay: ${DateFormat('dd/MM/yyyy').format(state.selectedDate)}",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Overview stats
                        _buildOverviewGrid(totalPatients, waiting, checkedIn, completed, formattedRevenue),
                        const SizedBox(height: 24),

                        // Quick actions
                        _buildQuickActions(context),
                        const SizedBox(height: 24),

                        // Visual Scheduler Card
                        _buildSchedulerCard(context, state.selectedDate),
                        const SizedBox(height: 24),

                        // Charts
                        _buildChartsSection(state.appointments),
                      ],
                    ),
                  );

                  if (isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: mainContent,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Card(
                              color: kCardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: kBorderColor),
                              ),
                              child: _selectedAppointment != null
                                  ? _buildAdministrativeDetailPanel(_selectedAppointment!)
                                  : _buildLiveQueueSection(state.appointments),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            mainContent,
                            const SizedBox(height: 24),
                            Card(
                              color: kCardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: kBorderColor),
                              ),
                              child: _buildLiveQueueSection(state.appointments),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
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
            _buildStatCard("Chờ Check-in", wait.toString(), Icons.hourglass_top_rounded, Colors.orange, onTap: () {
              context.go('/receptionist/appointment-management');
            }),
            _buildStatCard("Trong hàng chờ", checkedIn.toString(), Icons.directions_run_rounded, kSecondaryColor, onTap: () {
              context.go('/receptionist/waiting-list');
            }),
            _buildStatCard("Đã khám xong", done.toString(), Icons.check_circle_outline_rounded, kAccentColor),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      width: 172,
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: color.withOpacity(0.04),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
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
          ),
        ),
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

  Widget _buildChartsSection(List<Appointment> appointments) {
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

  Widget _buildPatientBarChart(List<Appointment> appointments) {
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

  Widget _buildSpecialtyPieChart(List<Appointment> appointments) {
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

  Widget _buildLiveQueueSection(List<Appointment> appointments) {
    final recent = appointments.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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

                return InkWell(
                  onTap: () => _selectAppointment(appt),
                  borderRadius: BorderRadius.circular(6),
                  hoverColor: kSecondaryColor.withOpacity(0.02),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
                    child: Row(
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
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  // ─── VISUAL SCHEDULER VIEW ──────────────────────────────────────────────────
  Widget _buildSchedulerCard(BuildContext context, DateTime selectedDate) {
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
                "Lịch làm việc phòng khám",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildSchedulerTabButton("day", "Ngày"),
                    _buildSchedulerTabButton("week", "Tuần"),
                    _buildSchedulerTabButton("month", "Tháng"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  if (_schedulerViewMode == "day") {
                    _shiftDate(-1);
                  } else if (_schedulerViewMode == "week") {
                    _shiftDate(-7);
                  } else if (_schedulerViewMode == "month") {
                    _shiftMonth(-1);
                  }
                },
              ),
              Text(
                _getNavigationLabel(selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  if (_schedulerViewMode == "day") {
                    _shiftDate(1);
                  } else if (_schedulerViewMode == "week") {
                    _shiftDate(7);
                  } else if (_schedulerViewMode == "month") {
                    _shiftMonth(1);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _loadingAll
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ))
              : _buildSchedulerContent(selectedDate),
        ],
      ),
    );
  }

  Widget _buildSchedulerTabButton(String mode, String label) {
    final isSelected = _schedulerViewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _schedulerViewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? kSecondaryColor : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getNavigationLabel(DateTime date) {
    if (_schedulerViewMode == "day") {
      return "Ngày ${DateFormat('dd/MM/yyyy').format(date)}";
    } else if (_schedulerViewMode == "week") {
      final start = _findFirstDayOfWeek(date);
      final end = start.add(const Duration(days: 6));
      return "Tuần ${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
    } else {
      return "Tháng ${DateFormat('MM/yyyy').format(date)}";
    }
  }

  void _shiftDate(int days) {
    final state = ref.read(receptionistProvider);
    final newDate = state.selectedDate.add(Duration(days: days));
    ref.read(receptionistProvider.notifier).fetchAppointments(newDate);
  }

  void _shiftMonth(int months) {
    final state = ref.read(receptionistProvider);
    final newDate = DateTime(state.selectedDate.year, state.selectedDate.month + months, state.selectedDate.day);
    ref.read(receptionistProvider.notifier).fetchAppointments(newDate);
  }

  Widget _buildSchedulerContent(DateTime selectedDate) {
    final state = ref.watch(receptionistProvider);
    if (_schedulerViewMode == "day") {
      final dayAppointments = state.appointments;
      if (dayAppointments.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Không có ca khám nào trong ngày này",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ),
        );
      }
      return _buildDayScheduler(dayAppointments);
    } else if (_schedulerViewMode == "week") {
      return _buildWeekScheduler(selectedDate);
    } else {
      return _buildMonthScheduler(selectedDate);
    }
  }

  Widget _buildDayScheduler(List<Appointment> dayAppointments) {
    final List<String> hours = ["08:00", "09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "16:00", "17:00"];
    
    return Column(
      children: hours.map((hour) {
        final hourPrefix = hour.split(":")[0];
        final matches = dayAppointments.where((appt) {
          final apptHour = appt.time.split(":")[0].padLeft(2, '0');
          return apptHour == hourPrefix;
        }).toList();

        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  hour,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: matches.isEmpty
                    ? Text(
                        "Không có ca khám",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: matches.map((appt) => _buildMiniAppointmentCard(appt)).toList(),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniAppointmentCard(Appointment appt) {
    Color statusColor = Colors.grey;
    switch (appt.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'confirmed': statusColor = Colors.blue; break;
      case 'checked_in': statusColor = kSecondaryColor; break;
      case 'completed': statusColor = kAccentColor; break;
      case 'cancelled': statusColor = Colors.red; break;
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _selectAppointment(appt),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "BS. ${appt.doctorName}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  appt.departmentName.isNotEmpty ? appt.departmentName : appt.doctorSpecialty,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appt.time,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor, fontSize: 11),
                    ),
                    Text(
                      appt.appointmentType == 'online' ? 'Online' : 'Tại PK',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _findFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildWeekScheduler(DateTime selectedDate) {
    final startOfWeek = _findFirstDayOfWeek(selectedDate);
    final days = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        if (isMobile) {
          return Column(
            children: days.map((day) => _buildWeekDayRow(day)).toList(),
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((day) => Expanded(child: _buildWeekDayColumn(day))).toList(),
          );
        }
      },
    );
  }

  Widget _buildWeekDayColumn(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isSelected = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(ref.read(receptionistProvider).selectedDate);
    
    final dayAppointments = _allAppointments.where((appt) => appt.date == dayStr).toList();

    return GestureDetector(
      onTap: () {
        ref.read(receptionistProvider.notifier).fetchAppointments(day);
        setState(() {
          _schedulerViewMode = "day";
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? kSecondaryColor.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kSecondaryColor : (isToday ? kAccentColor : kBorderColor),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getWeekdayName(day.weekday),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? kSecondaryColor : kTextColor,
              ),
            ),
            Text(
              DateFormat('dd/MM').format(day),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (dayAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Trống",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),
              )
            else
              ...dayAppointments.take(3).map((appt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildMiniAppointmentCardCompact(appt),
                );
              }),
            if (dayAppointments.length > 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "+${dayAppointments.length - 3} lịch",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayRow(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final dayAppointments = _allAppointments.where((appt) => appt.date == dayStr).toList();
    final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return InkWell(
      onTap: () {
        ref.read(receptionistProvider.notifier).fetchAppointments(day);
        setState(() {
          _schedulerViewMode = "day";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWeekdayName(day.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? kAccentColor : kTextColor,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(day),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: dayAppointments.isEmpty
                  ? Text("Trống", style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: dayAppointments.map((appt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: _buildMiniAppointmentCardCompact(appt),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAppointmentCardCompact(Appointment appt) {
    Color statusColor = Colors.grey;
    switch (appt.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'confirmed': statusColor = Colors.blue; break;
      case 'checked_in': statusColor = kSecondaryColor; break;
      case 'completed': statusColor = kAccentColor; break;
      case 'cancelled': statusColor = Colors.red; break;
    }

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _selectAppointment(appt),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${appt.time} • BS.${appt.doctorName.split(' ').last}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return "Thứ 2";
      case 2: return "Thứ 3";
      case 3: return "Thứ 4";
      case 4: return "Thứ 5";
      case 5: return "Thứ 6";
      case 6: return "Thứ 7";
      case 7: return "Chủ Nhật";
      default: return "";
    }
  }

  Widget _buildMonthScheduler(DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    
    final daysInMonth = lastDayOfMonth.day;
    final weekdayOfFirstDay = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    final paddingCells = weekdayOfFirstDay - 1;
    final totalCells = paddingCells + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    
    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            final dayName = _getWeekdayName(index + 1);
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    dayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextColor),
                  ),
                ),
              ),
            );
          }),
        ),
        const Divider(height: 1),
        ...List.generate(rowCount, (rowIndex) {
          return Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < paddingCells || cellIndex >= totalCells) {
                return const Expanded(child: SizedBox(height: 60));
              }
              
              final dayNumber = cellIndex - paddingCells + 1;
              final cellDate = DateTime(selectedDate.year, selectedDate.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
              final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isSelected = dateStr == DateFormat('yyyy-MM-dd').format(ref.read(receptionistProvider).selectedDate);
              
              final dayAppointments = _allAppointments.where((appt) => appt.date == dateStr).toList();
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(receptionistProvider.notifier).fetchAppointments(cellDate);
                    setState(() {
                      _schedulerViewMode = "day";
                    });
                  },
                  child: Container(
                    height: 70,
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? kSecondaryColor.withOpacity(0.04) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? kSecondaryColor : (isToday ? kAccentColor : kBorderColor.withOpacity(0.5)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                            color: isSelected ? kSecondaryColor : (isToday ? kAccentColor : kTextColor),
                          ),
                        ),
                        const Spacer(),
                        if (dayAppointments.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: kSecondaryColor, size: 6),
                                const SizedBox(width: 4),
                                Text(
                                  "${dayAppointments.length} ca",
                                  style: const TextStyle(
                                    color: kSecondaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  // ─── ADMINISTRATIVE DETAIL PANEL ───────────────────────────────────────────
  void _showDetailDialog(Appointment appt) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 450,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectionArea(
              child: _buildAdministrativeDetailPanel(appt, isDialog: true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdministrativeDetailPanel(Appointment appointment, {bool isDialog = false}) {
    final status = appointment.status;
    final isCanCheckIn = ['pending', 'confirmed'].contains(status);
    final typeLabel = appointment.appointmentType == 'online' ? '🎥 Khám Online (Video)' : '🏥 Khám tại phòng khám';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chi tiết Hành chính",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kSecondaryColor),
              ),
              IconButton(
                onPressed: () {
                  if (isDialog) {
                    Navigator.pop(context);
                  }
                  setState(() => _selectedAppointment = null);
                },
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                tooltip: "Đóng bảng chi tiết",
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),

          Row(
            children: [
              CircleAvatar(
                backgroundColor: kSecondaryColor.withOpacity(0.08),
                radius: 28,
                child: const Icon(Icons.person, color: kSecondaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(color: _getStatusTextColor(status), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: appointment.appointmentType == 'online'
                                ? const Color(0xFFE3F2FD)
                                : const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            appointment.appointmentType == 'online' ? 'Online' : 'Tại PK',
                            style: TextStyle(
                              color: appointment.appointmentType == 'online'
                                  ? const Color(0xFF0D47A1)
                                  : const Color(0xFF7B1FA2),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            "THÔNG TIN NHÂN KHẨU",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          _buildDetailInfoRow(Icons.phone, "Số điện thoại", appointment.phone),
          _buildDetailInfoRow(Icons.credit_card, "CCCD/CMND", appointment.cccd.isNotEmpty ? appointment.cccd : "Chưa cập nhật"),
          _buildDetailInfoRow(Icons.cake_outlined, "Ngày sinh", appointment.birthDate.isNotEmpty ? appointment.birthDate : "Chưa rõ"),
          _buildDetailInfoRow(Icons.wc_rounded, "Giới tính", appointment.gender.isNotEmpty ? appointment.gender : "Chưa rõ"),
          _buildDetailInfoRow(Icons.location_on_outlined, "Địa chỉ", appointment.address.isNotEmpty ? appointment.address : "Chưa cập nhật"),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),

          const Text(
            "THÔNG TIN LỊCH HẸN",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          _buildDetailInfoRow(Icons.medical_services_outlined, "Bác sĩ", appointment.doctorName),
          _buildDetailInfoRow(
            Icons.local_hospital_outlined,
            "Chuyên khoa",
            appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty,
          ),
          _buildDetailInfoRow(Icons.access_time_rounded, "Giờ hẹn", "${appointment.time} - ${appointment.date}"),
          _buildDetailInfoRow(Icons.category_outlined, "Hình thức", typeLabel),
          _buildDetailInfoRow(
            Icons.assignment_outlined,
            "Triệu chứng",
            appointment.reason.isNotEmpty ? appointment.reason : "Không mô tả",
          ),
          const SizedBox(height: 16),

          if (isCanCheckIn) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCheckInDialog(context, appointment, isDialog: isDialog),
                icon: const Icon(Icons.verified_user_outlined, size: 18, color: Colors.white),
                label: const Text(
                  "📍 Xác nhận Check-in",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (status == 'checked_in') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bệnh nhân đã Check-In.\nĐang trong hàng chờ khám Bác sĩ.",
                      style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await ref
                      .read(receptionistProvider.notifier)
                      .confirmAppointment(appointment.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã xác nhận lịch hẹn cho ${appointment.patientName}"),
                        backgroundColor: kPrimaryColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() {
                      _selectedAppointment = appointment.copyWith(status: 'confirmed');
                    });
                    _loadAllAppointments();
                    if (isDialog) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 16, color: kSecondaryColor),
                label: const Text(
                  "Xác nhận lịch hẹn",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kSecondaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kSecondaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildSecureGuard(),
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureGuard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "🔒 Quyền truy cập bị hạn chế",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Nội dung bệnh án, Đơn thuốc điện tử và các dữ liệu AI/CNN/KNN chỉ được hiển thị cho Bác sĩ đã xác thực.\n\nLễ tân chỉ có quyền truy cập dữ liệu Hành chính / Hóa đơn.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showCheckInDialog(BuildContext context, Appointment appointment, {bool isDialog = false}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 8),
            Text(
              "Xác Nhận Check-In",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vui lòng xác minh thông tin bệnh nhân trước khi check-in:",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildDialogInfoRow("Mã đặt lịch:", "#${appointment.id.toUpperCase()}"),
              _buildDialogInfoRow("Họ và tên:", appointment.patientName),
              _buildDialogInfoRow("CCCD/CMND:", appointment.cccd.isNotEmpty ? appointment.cccd : "Chưa cập nhật"),
              _buildDialogInfoRow("Số điện thoại:", appointment.phone),
              _buildDialogInfoRow("Bác sĩ khám:", appointment.doctorName),
              _buildDialogInfoRow("Chuyên khoa:", appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty),
              _buildDialogInfoRow("Giờ hẹn:", "${appointment.time} - ${appointment.date}"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bệnh nhân sẽ được xếp vào hàng chờ trực tiếp của Bác sĩ.",
                        style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(receptionistProvider.notifier)
                  .checkInPatient(appointment.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Đã check-in thành công cho ${appointment.patientName}"),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {
                    _selectedAppointment = appointment.copyWith(status: 'checked_in');
                  });
                  _loadAllAppointments();
                  if (isDialog) {
                    Navigator.pop(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lỗi check-in. Vui lòng thử lại."),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}