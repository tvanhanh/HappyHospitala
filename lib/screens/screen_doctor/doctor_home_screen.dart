import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/socket_service.dart';

// --- MODERN COLORS ---
const Color kPrimaryColor = Color(0xFF0066FF); // Vibrant Modern Blue
const Color kSecondaryColor = Color(0xFF00C6FF); // Cyan Gradient
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kCardColor = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextLight = Color(0xFF64748B);

void main() => runApp(const DoctorApp());

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoctorDashboard(),
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with SingleTickerProviderStateMixin {
  String doctorName = "";
  String specialty = "";
  String avatarUrl = "";
  String doctorId = "";

  List<Appointment> _appointments = [];
  List<Map<String, dynamic>> _medicalRecords = [];
  bool _isLoading = true;
  String _errorMessage = "";
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_DashboardItem> items = [
    _DashboardItem("Hồ sơ", Icons.person_outline, const Color(0xFF4F46E5), "/doctor/profile"),
    _DashboardItem("Lịch hẹn", Icons.calendar_today_rounded, const Color(0xFF0EA5E9), "/doctor/appointments"),
    _DashboardItem("Kê đơn", Icons.medication_outlined, const Color(0xFF10B981), "/doctor/appointments"),
    _DashboardItem("Bệnh nhân", Icons.people_outline, const Color(0xFFF59E0B), "/home/booking"),
    _DashboardItem("Dự đoán AI", Icons.auto_awesome_rounded, const Color(0xFF8B5CF6), "/diagnosis"),
    _DashboardItem("Bệnh án", Icons.assignment_ind_rounded, const Color(0xFFEC4899), "/doctor/medical-records"),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
    loadDoctorFromToken();
    _fetchData();
    _initSocketListener();

    // 🔥 AUTO REFRESH 10 GIÂY
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return false;
      await _fetchData();
      return true;
    });
  }

  void _initSocketListener() {
    SocketService.instance.on(SocketEvents.newNotification, (data) {
      if (mounted) {
        final Map<String, dynamic> notification = Map<String, dynamic>.from(data);
        final title = notification['title'] ?? 'Thông báo mới';
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
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.newNotification);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadDoctorFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString("name") ?? "Bác sĩ";
      specialty = prefs.getString("specialty") ?? "Nội tiết";
      avatarUrl = prefs.getString("avatarUrl") ?? prefs.getString("avatar") ?? "";
      doctorId = prefs.getString("userId") ?? prefs.getString("doctorId") ?? "";
    });
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDoctorId = prefs.getString("userId") ?? prefs.getString("doctorId") ?? "";

      // Load appointments
      final apps = await AppointmentApi.getByDoctor();
      // Load medical records
      final records = await MedicalRecordService.getMedicalRecord();

      if (!mounted) return;
      setState(() {
        _appointments = apps;
        // Filter records by the current doctor's ID
        _medicalRecords = records.where((r) {
          final rDocId = r['doctorId']?.toString() ?? '';
          return rDocId == currentDoctorId;
        }).toList();
        _isLoading = false;
        _errorMessage = "";
      });
    } catch (e) {
      debugPrint("FETCH DATA ERROR: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi tải dữ liệu: $e";
      });
    }
  }

  bool _isToday(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      final now = DateTime.now();
      final parsedDate = DateTime.parse(dateStr);
      return parsedDate.year == now.year &&
             parsedDate.month == now.month &&
             parsedDate.day == now.day;
    } catch (_) {
      final now = DateTime.now();
      final todayStr1 = DateFormat('yyyy-MM-dd').format(now);
      final todayStr2 = DateFormat('dd/MM/yyyy').format(now);
      return dateStr.contains(todayStr1) || dateStr.contains(todayStr2);
    }
  }

  Map<String, dynamic>? _getMedicalRecordForPatient(String patientId, String name) {
    if (_medicalRecords.isEmpty) return null;
    if (patientId.isNotEmpty) {
      final match = _medicalRecords.firstWhere(
        (r) => r['patientId']?.toString() == patientId,
        orElse: () => {},
      );
      if (match.isNotEmpty) return match;
    }
    if (name.isNotEmpty) {
      final match = _medicalRecords.firstWhere(
        (r) => r['patientName']?.toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      if (match.isNotEmpty) return match;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final todayExams = _appointments.where((a) => _isToday(a.date) && a.status != 'cancelled').length;
    final positiveCases = _medicalRecords.where((r) {
      final status = r['status']?.toString() ?? '';
      return status.contains('Y') || status.contains('Mắc bệnh');
    }).length;
    final negativeCases = _medicalRecords.where((r) {
      final status = r['status']?.toString() ?? '';
      return status.contains('N') || status.contains('Không');
    }).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsOverview(todayExams, positiveCases, negativeCases),
                      const SizedBox(height: 24),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildTabbedSection(),
                      const SizedBox(height: 32),
                      const Text(
                        "Công cụ & Tính năng",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kSecondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Xin chào, $doctorName",
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                specialty,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 35, color: kPrimaryColor) : null,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(int todayExams, int positiveCases, int negativeCases) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard("Lịch hôm nay", todayExams.toString(), Icons.calendar_today_rounded, kPrimaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Mắc bệnh TĐ", positiveCases.toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444))),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard("Không mắc bệnh", negativeCases.toString(), Icons.check_circle_outline_rounded, const Color(0xFF10B981), isFullWidth: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildStatCard("Ca khám hôm nay", todayExams.toString(), Icons.calendar_today_rounded, kPrimaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Mắc bệnh tiểu đường", positiveCases.toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Không mắc bệnh", negativeCases.toString(), Icons.check_circle_outline_rounded, const Color(0xFF10B981))),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: kTextLight, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedSection() {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bệnh nhân & Lịch trình",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: kPrimaryColor),
                    onPressed: _fetchData,
                    tooltip: "Tải lại dữ liệu",
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: kPrimaryColor,
              unselectedLabelColor: kTextLight,
              indicatorColor: kPrimaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 16),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: [
                Tab(text: "Hàng chờ khám"),
                Tab(text: "Lịch sử chẩn đoán"),
              ],
            ),
            const Divider(height: 1, color: Colors.black12),
            SizedBox(
              height: 380,
              child: TabBarView(
                children: [
                  _buildAppointmentsQueue(),
                  _buildDiagnosticsHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsQueue() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointments.isEmpty) {
      return _buildEmptyState("Chưa có lịch hẹn nào được đăng ký", Icons.event_busy_rounded);
    }

    // Filter appointments: order by status, prioritizing active status like pending, checked_in, in_progress
    final sortedApps = List<Appointment>.from(_appointments);
    sortedApps.sort((a, b) {
      // Show pending/checked_in/in_progress first, completed/cancelled last
      final aActive = a.status == 'checked_in' || a.status == 'in_progress' || a.status == 'pending';
      final bActive = b.status == 'checked_in' || b.status == 'in_progress' || b.status == 'pending';
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return b.date.compareTo(a.date);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedApps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = sortedApps[index];
        final record = _getMedicalRecordForPatient(app.patientId, app.patientName);
        final statusStr = record != null ? record['status']?.toString() ?? '' : '';

        return _buildAppointmentListItem(app, statusStr);
      },
    );
  }

  Widget _buildAppointmentListItem(Appointment app, String diseaseStatus) {
    final isDiagnosed = diseaseStatus.isNotEmpty;
    Color statusColor = Colors.orange;
    String statusLabel = "Chờ khám";
    if (isDiagnosed) {
      if (diseaseStatus.contains("Mắc bệnh") || diseaseStatus.contains("Y")) {
        statusColor = const Color(0xFFEF4444);
        statusLabel = "Mắc bệnh tiểu đường";
      } else {
        statusColor = const Color(0xFF10B981);
        statusLabel = "Không mắc bệnh tiểu đường";
      }
    } else {
      // Use appointment status if not diagnosed yet
      if (app.status == 'checked_in') {
        statusLabel = "Đã check-in";
        statusColor = const Color(0xFF0EA5E9);
      } else if (app.status == 'in_progress') {
        statusLabel = "Đang khám";
        statusColor = Colors.purple;
      } else if (app.status == 'completed') {
        statusLabel = "Hoàn thành";
        statusColor = const Color(0xFF10B981);
      } else if (app.status == 'cancelled') {
        statusLabel = "Đã huỷ";
        statusColor = Colors.red;
      }
    }

    return InkWell(
      onTap: () {
        context.push(
          '/doctor/appointments/appointment-detail',
          extra: app,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              backgroundImage: app.patientAvatar.isNotEmpty ? NetworkImage(app.patientAvatar) : null,
              child: app.patientAvatar.isEmpty ? const Icon(Icons.person, color: kPrimaryColor) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.patientName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${app.gender} • ${app.birthDate.isNotEmpty ? _calculateAge(app.birthDate) : 'Tuổi: N/A'}",
                        style: const TextStyle(fontSize: 12, color: kTextLight),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          app.time,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!isDiagnosed && app.status != 'cancelled' && app.status != 'completed') ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      context.push('/doctor/create-medical-record', extra: app);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "Chẩn đoán",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$age tuổi";
    } catch (_) {
      return birthDateStr;
    }
  }

  Widget _buildDiagnosticsHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_medicalRecords.isEmpty) {
      return _buildEmptyState("Chưa có hồ sơ bệnh án nào được tạo", Icons.folder_off_rounded);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _medicalRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _medicalRecords[index];
        return _buildDiagnosticListItem(record);
      },
    );
  }

  Widget _buildDiagnosticListItem(Map<String, dynamic> record) {
    final diseaseStatus = record['status']?.toString() ?? '';
    Color statusColor = Colors.grey;
    String statusLabel = "Chưa rõ";
    if (diseaseStatus.contains("Mắc bệnh") || diseaseStatus.contains("Y")) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = "Mắc bệnh tiểu đường";
    } else if (diseaseStatus.contains("Không") || diseaseStatus.contains("N")) {
      statusColor = const Color(0xFF10B981);
      statusLabel = "Không mắc bệnh tiểu đường";
    } else {
      statusLabel = diseaseStatus.isNotEmpty ? diseaseStatus : "Không mắc bệnh tiểu đường";
      statusColor = const Color(0xFF10B981);
    }

    final hba1c = record['hba1c']?.toString() ?? '';
    final bmi = record['bmi']?.toString() ?? '';
    final creatinine = record['creatinine']?.toString() ?? '';
    final urea = record['urea']?.toString() ?? '';

    final dateStr = record['visitDate']?.toString() ?? record['createdAt']?.toString() ?? '';
    String formattedDate = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {}

    return InkWell(
      onTap: () {
        final recordId = record['id'] ?? record['_id'] ?? '';
        if (recordId.isNotEmpty) {
          context.push('/medical-record-detail/$recordId');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.1),
                  backgroundImage: record['patientAvatar'] != null && record['patientAvatar'].toString().isNotEmpty
                      ? NetworkImage(record['patientAvatar'].toString())
                      : null,
                  child: record['patientAvatar'] == null || record['patientAvatar'].toString().isEmpty
                      ? Icon(Icons.assignment_ind_rounded, size: 20, color: statusColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['patientName']?.toString() ?? 'Không rõ tên',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 11, color: kTextLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (hba1c.isNotEmpty || bmi.isNotEmpty || creatinine.isNotEmpty || urea.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hba1c.isNotEmpty) _buildMiniIndicator("HbA1c", "$hba1c%"),
                    if (bmi.isNotEmpty) _buildMiniIndicator("BMI", bmi),
                    if (creatinine.isNotEmpty) _buildMiniIndicator("Creatinine", creatinine),
                    if (urea.isNotEmpty) _buildMiniIndicator("Urea", urea),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIndicator(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: kTextLight),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: kTextLight.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextLight.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return _buildMenuCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildMenuCard(_DashboardItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.push(item.route);
          loadDoctorFromToken();
          _fetchData();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.color.withOpacity(0.2), item.color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: kBackgroundColor,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kSecondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 30, color: kPrimaryColor) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(Icons.settings_outlined, "Hồ sơ & Cài đặt", () async {
              Navigator.pop(context); // Close drawer first
              await context.push('/doctor/profile');
              loadDoctorFromToken();
              _fetchData();
            }),
            _buildDrawerItem(Icons.assignment_ind_rounded, "Hồ sơ bệnh án", () async {
              Navigator.pop(context); // Close drawer first
              await context.push('/doctor/medical-records');
            }),
            _buildDrawerItem(Icons.help_outline_rounded, "Trợ giúp & Hỗ trợ", () {}),
            const Spacer(),
            const Divider(height: 1, color: Colors.black12),
            _buildDrawerItem(
              Icons.logout_rounded,
              "Đăng xuất",
              () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) context.go('/auth/login');
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : kTextDark;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _DashboardItem(this.title, this.icon, this.color, this.route);
}
