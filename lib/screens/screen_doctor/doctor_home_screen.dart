import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/providers/medical_qa_provider.dart';
import 'package:flutter_application_datlichkham/services/medical_qa_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';

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

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  String doctorName = "";
  String specialty = "";
  String avatarUrl = "";
  String doctorId = "";
  final doctorSpecialtyProvider = StateProvider<String>((ref) => '');
  List<Appointment> _appointments = [];
  List<Map<String, dynamic>> _medicalRecords = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _queueFilter = "today";
  // "today" or "week"

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  DateTime? _selectedFilterDate;

  final List<_DashboardItem> items = [
    _DashboardItem("Hồ sơ", Icons.person_outline, const Color(0xFF4F46E5),
        "/doctor/profile"),
    _DashboardItem("Lịch hẹn", Icons.calendar_today_rounded,
        const Color(0xFF0EA5E9), "/doctor/appointments"),
    _DashboardItem("Bệnh nhân", Icons.people_outline, const Color(0xFFF59E0B),
        "/home/booking"),
    _DashboardItem("Bệnh án", Icons.assignment_ind_rounded,
        const Color(0xFFEC4899), "/doctor/medical-records"),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
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

  bool isLoading = false;

  void _initSocketListener() {
    SocketService.instance.on(SocketEvents.newNotification, (data) {
      if (mounted) {
        final Map<String, dynamic> notification =
            Map<String, dynamic>.from(data);
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    SocketService.instance.off(SocketEvents.newNotification);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadDoctorFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString("name") ?? "Bác sĩ";
      specialty = prefs.getString("specialty") ?? "Nội tiết";
      avatarUrl =
          prefs.getString("avatarUrl") ?? prefs.getString("avatar") ?? "";
      doctorId = prefs.getString("userId") ?? prefs.getString("doctorId") ?? "";
    });

    // 👉 THÊM DÒNG 1: Báo cho Riverpod biết chuyên khoa lấy từ bộ nhớ đệm
    // (Giúp banner hiện đúng ngay lập tức lúc vừa mở app)
    ref.read(doctorSpecialtyProvider.notifier).state = specialty;

    try {
      final docProfile = await ApiService.getDoctorProfile();
      final newName = docProfile['fullName'] ?? doctorName;
      final newAvatar = docProfile['avatar'] ?? avatarUrl;

      String newSpecialty = specialty;
      if (docProfile['specialtyId'] is Map) {
        newSpecialty = docProfile['specialtyId']['departmentName'] ??
            docProfile['specialtyId']['name'] ??
            specialty;
      }

      await prefs.setString("name", newName);
      await prefs.setString("avatar", newAvatar);
      await prefs.setString("avatarUrl", newAvatar);
      await prefs.setString("specialty", newSpecialty);

      if (mounted) {
        setState(() {
          doctorName = newName;
          avatarUrl = newAvatar;
          specialty = newSpecialty;
        });

        // 👉 THÊM DÒNG 2: Báo lại cho Riverpod nếu API trả về tên chuyên khoa mới cập nhật
        ref.read(doctorSpecialtyProvider.notifier).state = newSpecialty;
      }
    } catch (e) {
      debugPrint("Error loading doctor profile: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDoctorId =
          prefs.getString("userId") ?? prefs.getString("doctorId") ?? "";

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

  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  bool _isPast(String dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pDate = DateTime(parsed.year, parsed.month, parsed.day);
    return pDate.isBefore(today);
  }

  bool _isToday(String dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  bool _isTomorrow(String dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) return false;
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return parsed.year == tomorrow.year &&
        parsed.month == tomorrow.month &&
        parsed.day == tomorrow.day;
  }

  bool _isThisWeek(String dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) return false;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final start =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end =
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
    final pDate = DateTime(parsed.year, parsed.month, parsed.day);

    return pDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
        pDate.isBefore(end.add(const Duration(seconds: 1)));
  }

  String _getWeekdayName(String dateStr) {
    try {
      final date = _tryParseDate(dateStr);
      if (date == null) return "Chưa xác định";
      switch (date.weekday) {
        case DateTime.monday:
          return "Thứ Hai";
        case DateTime.tuesday:
          return "Thứ Ba";
        case DateTime.wednesday:
          return "Thứ Tư";
        case DateTime.thursday:
          return "Thứ Năm";
        case DateTime.friday:
          return "Thứ Sáu";
        case DateTime.saturday:
          return "Thứ Bảy";
        case DateTime.sunday:
          return "Chủ Nhật";
        default:
          return "Chưa xác định";
      }
    } catch (_) {
      return "Chưa xác định";
    }
  }

  String _getWeekdayFormattedTitle(String dateStr) {
    try {
      final date = _tryParseDate(dateStr);
      if (date == null) return dateStr;
      final dayName = _getWeekdayName(dateStr);
      final formattedDate = DateFormat('dd/MM').format(date);
      return "$dayName ($formattedDate)";
    } catch (_) {
      return dateStr;
    }
  }

  Map<String, dynamic> _getDiseaseLabelAndColor(String diseaseStatus,
      {String department = ""}) {
    if (diseaseStatus.isEmpty) {
      return {
        'label': 'Chờ khám',
        'color': Colors.orange,
      };
    }

    final cleanStatus = diseaseStatus.toLowerCase();
    final isSkinDept = department.toLowerCase().contains("da liễu") ||
        cleanStatus.contains("mel") ||
        cleanStatus.contains("bcc") ||
        cleanStatus.contains("basal") ||
        cleanStatus.contains("akiec") ||
        cleanStatus.contains("bkl") ||
        cleanStatus.contains("nv") ||
        cleanStatus.contains("df") ||
        cleanStatus.contains("vasc");

    if (cleanStatus.contains("mắc bệnh") ||
        (cleanStatus.contains("y") && cleanStatus.length == 1) ||
        cleanStatus.contains("melanoma") ||
        cleanStatus.contains("mel") ||
        cleanStatus.contains("bcc") ||
        cleanStatus.contains("basal") ||
        cleanStatus.contains("akiec") ||
        cleanStatus.contains("carcinoma") ||
        cleanStatus.contains("ung thư") ||
        cleanStatus.contains("ác tính")) {
      Color color = const Color(0xFFEF4444);
      String label =
          isSkinDept ? "Nghi ngờ mắc bệnh (AI)" : "Mắc bệnh tiểu đường";

      if (cleanStatus.contains("tiểu đường")) {
        label = "Mắc bệnh tiểu đường";
      } else if (cleanStatus.contains("mel")) {
        label = "Mắc bệnh Melanoma";
      } else if (cleanStatus.contains("bcc") || cleanStatus.contains("basal")) {
        label = "Mắc bệnh BCC (Ung thư đáy)";
      } else if (cleanStatus.contains("akiec")) {
        label = "Bệnh Dày sừng ánh sáng";
      }

      return {
        'label': label,
        'color': color,
      };
    } else {
      Color color = const Color(0xFF10B981);
      String label =
          isSkinDept ? "Bình thường / Lành tính" : "Không mắc bệnh tiểu đường";

      if (cleanStatus.contains("không")) {
        label = isSkinDept ? "Không mắc bệnh" : "Không mắc bệnh tiểu đường";
      } else if (cleanStatus.contains("bkl")) {
        label = "Dày sừng lành tính (BKL)";
      } else if (cleanStatus.contains("nv")) {
        label = "Nốt ruồi lành tính (NV)";
      } else if (cleanStatus.contains("df")) {
        label = "U sợi da lành tính (DF)";
      } else if (cleanStatus.contains("vasc")) {
        label = "Tổn thương mạch máu (VASC)";
      }

      return {
        'label': label,
        'color': color,
      };
    }
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  // Thêm tham số List<MedicalPost> vào đây
  Widget _buildConsultationBanner(List<MedicalPost> pendingQuestions) {
    // Mở lại dòng này: Nếu không có câu nào chờ thì ẩn banner cho gọn
    if (pendingQuestions.isEmpty) return const SizedBox.shrink();

    // Dùng .title thay vì ['title'] vì đây là Object MedicalPost
    final latestQuestionTitle = pendingQuestions.first.title;
    final count = pendingQuestions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [BoxShadow(color: Colors.blue.shade50, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active,
              color: Colors.blue.shade700, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count câu hỏi đang chờ bạn tư vấn",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Gần nhất: $latestQuestionTitle",
                  style: TextStyle(color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Dùng context.push và ném cái post vào tham số extra
              context.push(
                '/qa-specialty',
                extra: pendingQuestions.first, // Ném nguyên cục dữ liệu sang
              );
            },
            child: const Text("Tư vấn ngay"),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Tìm tên bệnh nhân...",
                  hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: kTextLight, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: kTextLight, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickFilterDate,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _selectedFilterDate != null
                    ? kPrimaryColor
                    : kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color:
                        _selectedFilterDate != null ? Colors.white : kTextLight,
                    size: 20,
                  ),
                  if (_selectedFilterDate != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM').format(_selectedFilterDate!),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterDate = null;
                        });
                      },
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getMedicalRecordForPatient(
      String patientId, String name) {
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
    final pendingQuestionsProvider = Provider<List<MedicalPost>>((ref) {
      final postsAsyncValue = ref.watch(qaPostsProvider);

      // Nó nhảy vào đây nó "đọc" cái hộp chứa xem đang có chữ gì:
      final currentSpecialty = ref.watch(doctorSpecialtyProvider);

      return postsAsyncValue.maybeWhen(
        data: (posts) {
          return posts.where((p) {
            final isUnanswered = p.comments.isEmpty;
            // So sánh mảng tags với cái chữ đang có trong hộp chứa
            final isMatchingSpecialty = currentSpecialty.isEmpty ||
                p.tags.any((tag) =>
                    tag.toLowerCase().contains(currentSpecialty.toLowerCase()));
            return isUnanswered && isMatchingSpecialty;
          }).toList();
        },
        orElse: () => [],
      );
    });
    final pendingQuestions = ref.watch(pendingQuestionsProvider);

    final todayExams = _appointments
        .where((a) => _isToday(a.date) && a.status != 'cancelled')
        .length;
    final positiveCases = _medicalRecords.where((r) {
      final status = (r['status']?.toString() ?? '').toLowerCase();
      final diagnosis = (r['diagnosis']?.toString() ?? '').toLowerCase();
      final checkVal = status.isNotEmpty ? status : diagnosis;

      if (checkVal.contains('bkl') ||
          checkVal.contains('nv') ||
          checkVal.contains('df') ||
          checkVal.contains('vasc')) {
        return false;
      }

      return (checkVal.contains('y') == true && checkVal.length == 1) ||
          checkVal.contains('mắc bệnh') ||
          checkVal.contains('tiểu đường') ||
          checkVal.contains('melanoma') ||
          checkVal.contains('mel') ||
          checkVal.contains('bcc') ||
          checkVal.contains('basal') ||
          checkVal.contains('akiec') ||
          checkVal.contains('carcinoma') ||
          checkVal.contains('ung thư') ||
          checkVal.contains('ác tính');
    }).length;
    final negativeCases = _medicalRecords.where((r) {
      final status = (r['status']?.toString() ?? '').toLowerCase();
      final diagnosis = (r['diagnosis']?.toString() ?? '').toLowerCase();
      final checkVal = status.isNotEmpty ? status : diagnosis;

      if (checkVal.contains('bkl') ||
          checkVal.contains('nv') ||
          checkVal.contains('df') ||
          checkVal.contains('vasc')) {
        return true;
      }

      return (checkVal.contains('n') == true && checkVal.length == 1) ||
          checkVal.contains('không') ||
          checkVal.contains('lành tính') ||
          checkVal.contains('normal') ||
          checkVal.contains('benign');
    }).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsOverview(
                                  todayExams, positiveCases, negativeCases),
                              const SizedBox(height: 24),
                              _buildConsultationBanner(pendingQuestions),
                              const SizedBox(height: 24),
                              if (_errorMessage.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child:
                                          _buildTabbedSection(isDesktop: true),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Công cụ & Tính năng",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: kTextDark),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildFeatureGrid(isDesktop: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildTabbedSection(isDesktop: false),
                                const SizedBox(height: 32),
                                const Text(
                                  "Công cụ & Tính năng",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: kTextDark),
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureGrid(isDesktop: false),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM yyyy')
                                  .format(DateTime.now()),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Xin chào, BS. $doctorName",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                specialty,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2),
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
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 35, color: kPrimaryColor)
                                  : null,
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

  Widget _buildStatsOverview(
      int todayExams, int positiveCases, int negativeCases) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          "Lịch hôm nay",
                          todayExams.toString(),
                          Icons.calendar_today_rounded,
                          kPrimaryColor)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard(
                          "Mắc bệnh (AI)",
                          positiveCases.toString(),
                          Icons.warning_amber_rounded,
                          const Color(0xFFEF4444))),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                  "Bình thường / Lành tính",
                  negativeCases.toString(),
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF10B981),
                  isFullWidth: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
                child: _buildStatCard("Ca khám hôm nay", todayExams.toString(),
                    Icons.calendar_today_rounded, kPrimaryColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    "Phát hiện bệnh (AI)",
                    positiveCases.toString(),
                    Icons.warning_amber_rounded,
                    const Color(0xFFEF4444))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    "Bình thường / Lành tính",
                    negativeCases.toString(),
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF10B981))),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool isFullWidth = false}) {
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
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextDark),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: kTextLight,
                      fontWeight: FontWeight.w500),
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

  Widget _buildTabbedSection({bool isDesktop = false}) {
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDark),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: kPrimaryColor),
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
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: [
                Tab(text: "Hàng chờ khám"),
                Tab(text: "Lịch sử chẩn đoán"),
              ],
            ),
            const Divider(height: 1, color: Colors.black12),
            _buildSearchBar(),
            SizedBox(
              height: isDesktop ? 650 : 430,
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

  Widget _buildFilterButton(String filterType, String label, IconData icon) {
    final isSelected = _queueFilter == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _queueFilter = filterType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : kTextLight, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : kTextDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color.withOpacity(0.15),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsQueue() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _appointments.where((app) {
      if (_queueFilter == 'today') {
        return _isToday(app.date);
      } else if (_queueFilter == 'tomorrow') {
        return _isTomorrow(app.date);
      } else if (_queueFilter == 'week') {
        return _isThisWeek(app.date);
      } else {
        // "history" filter - show past or completed/cancelled appointments
        return _isPast(app.date) ||
            app.status == 'completed' ||
            app.status == 'cancelled';
      }
    }).toList();

    var resultList = filtered;
    if (_selectedFilterDate != null) {
      resultList = resultList.where((app) {
        final parsed = _tryParseDate(app.date);
        if (parsed == null) return false;
        return parsed.year == _selectedFilterDate!.year &&
            parsed.month == _selectedFilterDate!.month &&
            parsed.day == _selectedFilterDate!.day;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      resultList = resultList.where((app) {
        return app.patientName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    List<Widget> listItems = [];

    // Filter Buttons Row (4 Buttons: Hôm nay, Ngày mai, Tuần này, Lịch sử)
    listItems.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child:
                  _buildFilterButton("today", "Hôm nay", Icons.today_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildFilterButton(
                  "tomorrow", "Ngày mai", Icons.calendar_today_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildFilterButton(
                  "week", "Tuần này", Icons.calendar_view_week_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildFilterButton(
                  "history", "Lịch sử", Icons.history_rounded),
            ),
          ],
        ),
      ),
    );

    if (resultList.isEmpty) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _buildEmptyState(
              (_searchQuery.isNotEmpty || _selectedFilterDate != null)
                  ? "Không tìm thấy lịch hẹn phù hợp"
                  : (_queueFilter == 'today'
                      ? "Chưa có lịch khám nào hôm nay"
                      : (_queueFilter == 'tomorrow'
                          ? "Chưa có lịch khám nào ngày mai"
                          : (_queueFilter == 'week'
                              ? "Chưa có lịch khám nào tuần này"
                              : "Không có lịch sử khám nào"))),
              (_searchQuery.isNotEmpty || _selectedFilterDate != null)
                  ? Icons.search_off_rounded
                  : Icons.event_note_rounded),
        ),
      );
    } else if (_queueFilter == 'today' || _queueFilter == 'tomorrow') {
      final activeQueue = resultList
          .where((a) => a.status == 'checked_in' || a.status == 'in_progress')
          .toList();
      activeQueue.sort((a, b) => a.time.compareTo(b.time));

      final upcomingQueue = resultList
          .where((a) => a.status == 'pending' || a.status == 'confirmed')
          .toList();
      upcomingQueue.sort((a, b) => a.time.compareTo(b.time));

      final completedQueue = resultList
          .where((a) => a.status == 'completed' || a.status == 'cancelled')
          .toList();
      completedQueue.sort((a, b) => b.time.compareTo(a.time));

      if (activeQueue.isNotEmpty) {
        listItems.add(_buildSectionHeader(
            "Hàng đợi khám (${activeQueue.length})",
            Icons.run_circle_outlined,
            Colors.green));
        for (int i = 0; i < activeQueue.length; i++) {
          final app = activeQueue[i];
          final record =
              _getMedicalRecordForPatient(app.patientId, app.patientName);
          final statusStr = record != null
              ? (record['status']?.toString().isNotEmpty == true
                  ? record['status'].toString()
                  : record['diagnosis']?.toString() ?? '')
              : '';
          listItems
              .add(_buildAppointmentListItem(app, statusStr, sttNumber: i + 1));
        }
      }

      if (upcomingQueue.isNotEmpty) {
        listItems.add(_buildSectionHeader(
            "Lịch hẹn chưa Check-in (${upcomingQueue.length})",
            Icons.hourglass_empty_rounded,
            Colors.orange));
        for (var app in upcomingQueue) {
          final record =
              _getMedicalRecordForPatient(app.patientId, app.patientName);
          final statusStr = record != null
              ? (record['status']?.toString().isNotEmpty == true
                  ? record['status'].toString()
                  : record['diagnosis']?.toString() ?? '')
              : '';
          listItems.add(_buildAppointmentListItem(app, statusStr));
        }
      }

      if (completedQueue.isNotEmpty) {
        listItems.add(_buildSectionHeader(
            "Đã khám / Đã hủy (${completedQueue.length})",
            Icons.history_toggle_off_rounded,
            Colors.grey));
        for (var app in completedQueue) {
          final record =
              _getMedicalRecordForPatient(app.patientId, app.patientName);
          final statusStr = record != null
              ? (record['status']?.toString().isNotEmpty == true
                  ? record['status'].toString()
                  : record['diagnosis']?.toString() ?? '')
              : '';
          listItems.add(_buildAppointmentListItem(app, statusStr));
        }
      }
    } else if (_queueFilter == 'week') {
      final Map<DateTime, List<Appointment>> groupedByDateTime = {};
      for (var app in resultList) {
        final parsed = _tryParseDate(app.date);
        final dateKey = parsed != null
            ? DateTime(parsed.year, parsed.month, parsed.day)
            : DateTime(2000, 1, 1);
        if (!groupedByDateTime.containsKey(dateKey)) {
          groupedByDateTime[dateKey] = [];
        }
        groupedByDateTime[dateKey]!.add(app);
      }

      final sortedDates = groupedByDateTime.keys.toList()..sort();
      for (var dateKey in sortedDates) {
        final apps = groupedByDateTime[dateKey]!;
        apps.sort((a, b) => a.time.compareTo(b.time));

        final dateStr = DateFormat('yyyy-MM-dd').format(dateKey);
        final title = _getWeekdayFormattedTitle(dateStr);
        listItems.add(_buildSectionHeader(
            title, Icons.calendar_today_outlined, kPrimaryColor));

        for (int i = 0; i < apps.length; i++) {
          final app = apps[i];
          final record =
              _getMedicalRecordForPatient(app.patientId, app.patientName);
          final statusStr = record != null
              ? (record['status']?.toString().isNotEmpty == true
                  ? record['status'].toString()
                  : record['diagnosis']?.toString() ?? '')
              : '';
          listItems
              .add(_buildAppointmentListItem(app, statusStr, sttNumber: i + 1));
        }
      }
    } else {
      final Map<DateTime, List<Appointment>> groupedByDateTime = {};
      for (var app in resultList) {
        final parsed = _tryParseDate(app.date);
        final dateKey = parsed != null
            ? DateTime(parsed.year, parsed.month, parsed.day)
            : DateTime(2000, 1, 1);
        if (!groupedByDateTime.containsKey(dateKey)) {
          groupedByDateTime[dateKey] = [];
        }
        groupedByDateTime[dateKey]!.add(app);
      }

      final sortedDates = groupedByDateTime.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      for (var dateKey in sortedDates) {
        final apps = groupedByDateTime[dateKey]!;
        apps.sort((a, b) => a.time.compareTo(b.time));

        final dateStr = DateFormat('yyyy-MM-dd').format(dateKey);
        final title = _getWeekdayFormattedTitle(dateStr);
        listItems.add(_buildSectionHeader(
            title, Icons.history_rounded, Colors.grey.shade600));

        for (int i = 0; i < apps.length; i++) {
          final app = apps[i];
          final record =
              _getMedicalRecordForPatient(app.patientId, app.patientName);
          final statusStr = record != null
              ? (record['status']?.toString().isNotEmpty == true
                  ? record['status'].toString()
                  : record['diagnosis']?.toString() ?? '')
              : '';
          listItems
              .add(_buildAppointmentListItem(app, statusStr, sttNumber: i + 1));
        }
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listItems.length,
      separatorBuilder: (_, index) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        return listItems[index];
      },
    );
  }

  Widget _buildAppointmentListItem(Appointment app, String diseaseStatus,
      {int? sttNumber}) {
    final isDiagnosed = diseaseStatus.isNotEmpty;
    Color statusColor = Colors.orange;
    String statusLabel = "Chờ khám";
    if (isDiagnosed) {
      final info = _getDiseaseLabelAndColor(diseaseStatus,
          department: app.departmentName);
      statusLabel = info['label'] as String;
      statusColor = info['color'] as Color;
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
            if (sttNumber != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kSecondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  sttNumber < 10 ? "0$sttNumber" : "$sttNumber",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            CircleAvatar(
              radius: 24,
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              backgroundImage: app.patientAvatar.isNotEmpty
                  ? NetworkImage(app.patientAvatar)
                  : null,
              child: app.patientAvatar.isEmpty
                  ? const Icon(Icons.person, color: kPrimaryColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.patientName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kTextDark),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          app.time,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kTextLight),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (!isDiagnosed &&
                    !_isPast(app.date) &&
                    (app.status == 'checked_in' ||
                        app.status == 'in_progress')) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      context.push('/doctor/appointments/appointment-detail',
                          extra: app);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text(
                            "Vào khám",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
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

    var filteredRecords = _medicalRecords;
    if (_selectedFilterDate != null) {
      filteredRecords = filteredRecords.where((record) {
        final dateStr = record['visitDate']?.toString() ??
            record['createdAt']?.toString() ??
            '';
        final parsed = _tryParseDate(dateStr);
        if (parsed == null) return false;
        return parsed.year == _selectedFilterDate!.year &&
            parsed.month == _selectedFilterDate!.month &&
            parsed.day == _selectedFilterDate!.day;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredRecords = filteredRecords.where((record) {
        final name = (record['patientName']?.toString() ?? '').toLowerCase();
        final diagnosis = (record['diagnosis']?.toString() ?? '').toLowerCase();
        final status = (record['status']?.toString() ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            diagnosis.contains(_searchQuery) ||
            status.contains(_searchQuery);
      }).toList();
    }

    if (filteredRecords.isEmpty) {
      if (_searchQuery.isNotEmpty || _selectedFilterDate != null) {
        return _buildEmptyState(
            "Không tìm thấy hồ sơ bệnh án phù hợp", Icons.search_off_rounded);
      }
      return _buildEmptyState(
          "Chưa có hồ sơ bệnh án nào được tạo", Icons.folder_off_rounded);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return _buildDiagnosticListItem(record);
      },
    );
  }

  Widget _buildDiagnosticListItem(Map<String, dynamic> record) {
    final status = (record['status']?.toString() ?? '').trim();
    final diagnosis = (record['diagnosis']?.toString() ?? '').trim();
    final diseaseStatus = status.isNotEmpty ? status : diagnosis;
    final deptName = record['departmentName']?.toString() ?? '';

    final info = _getDiseaseLabelAndColor(diseaseStatus, department: deptName);
    final statusLabel = info['label'] as String;
    final statusColor = info['color'] as Color;

    final hba1c = record['hba1c']?.toString() ?? '';
    final bmi = record['bmi']?.toString() ?? '';
    final creatinine = record['creatinine']?.toString() ?? '';
    final urea = record['urea']?.toString() ?? '';

    final dateStr = record['visitDate']?.toString() ??
        record['createdAt']?.toString() ??
        '';
    String formattedDate = dateStr;
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
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
                  backgroundImage: record['patientAvatar'] != null &&
                          record['patientAvatar'].toString().isNotEmpty
                      ? NetworkImage(record['patientAvatar'].toString())
                      : null,
                  child: record['patientAvatar'] == null ||
                          record['patientAvatar'].toString().isEmpty
                      ? Icon(Icons.assignment_ind_rounded,
                          size: 20, color: statusColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['patientName']?.toString() ?? 'Không rõ tên',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kTextDark),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (hba1c.isNotEmpty ||
                bmi.isNotEmpty ||
                creatinine.isNotEmpty ||
                urea.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hba1c.isNotEmpty)
                      _buildMiniIndicator("HbA1c", "$hba1c%"),
                    if (bmi.isNotEmpty) _buildMiniIndicator("BMI", bmi),
                    if (creatinine.isNotEmpty)
                      _buildMiniIndicator("Creatinine", creatinine),
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
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: kTextLight),
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
              style:
                  TextStyle(fontSize: 14, color: kTextLight.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid({bool isDesktop = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount =
            isDesktop ? 2 : (constraints.maxWidth > 600 ? 4 : 2);
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
                    colors: [
                      item.color.withOpacity(0.2),
                      item.color.withOpacity(0.05)
                    ],
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
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextDark),
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
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
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
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(40)),
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
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 30, color: kPrimaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(Icons.settings_outlined, "Hồ sơ & Cài đặt",
                () async {
              Navigator.pop(context); // Close drawer first
              await context.push('/doctor/profile');
              loadDoctorFromToken();
              _fetchData();
            }),
            _buildDrawerItem(Icons.assignment_ind_rounded, "Hồ sơ bệnh án",
                () async {
              Navigator.pop(context); // Close drawer first
              await context.push('/doctor/medical-records');
            }),
            _buildDrawerItem(Icons.contact_support_rounded, "Góc Tư vấn Q&A",
                () async {
              Navigator.pop(context); // Close drawer first
              await context.push('/qa-specialty');
            }),
            _buildDrawerItem(
                Icons.help_outline_rounded, "Trợ giúp & Hỗ trợ", () {}),
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : kTextDark;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 15)),
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
