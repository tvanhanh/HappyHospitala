import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_aiService.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import 'package:image_picker/image_picker.dart';
import 'PrescriptionScreen.dart';

class AppointmentDetailDoctorScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailDoctorScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailDoctorScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends State<AppointmentDetailDoctorScreen> {
  final ScrollController _scrollController = ScrollController();
  double avatarOpacity = 1;
  List<Map<String, dynamic>> patientHistory = [];
  bool loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      double newOpacity = 1 - (offset / 120);
      newOpacity = newOpacity.clamp(0.0, 1.0);
      setState(() {
        avatarOpacity = newOpacity;
      });
    });
    fetchPatientHistory();
  }

  Future<void> fetchPatientHistory() async {
    try {
      final records = await MedicalRecordService.getMedicalRecord();
      if (!mounted) return;
      setState(() {
        // Filter history records for this specific patient
        patientHistory = records.where((rec) {
          final matchesName = rec['patientName']?.toString().toLowerCase() ==
              widget.appointment.patientName.toLowerCase();
          final matchesEmail = rec['email']?.toString().toLowerCase() ==
              widget.appointment.patientEmail.toLowerCase();
          return matchesName || matchesEmail;
        }).toList();
        loadingHistory = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => loadingHistory = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _calculateAge(String birthDateStr) {
    if (birthDateStr.isEmpty) return 0;
    try {
      final dob = DateTime.parse(birthDateStr);
      return DateTime.now().year - dob.year;
    } catch (_) {
      final regExp = RegExp(r'\d{4}');
      final match = regExp.firstMatch(birthDateStr);
      if (match != null) {
        final year = int.tryParse(match.group(0)!);
        if (year != null) {
          return DateTime.now().year - year;
        }
      }
      return 20; // Default fallback age
    }
  }

  String _formatDateToDdMmYyyy(String dateStr) {
    if (dateStr.isEmpty) return DateFormat('dd/MM/yyyy').format(DateTime.now());
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return "${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}";
          } else if (parts[2].length == 4) {
            return "${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}";
          }
        }
      }
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          if (parts[2].length == 4) {
            return "${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}";
          }
        }
      }
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'CHỜ XÁC NHẬN';
      case 'confirmed':
        return 'ĐÃ XÁC NHẬN';
      case 'checked_in':
        return 'ĐÃ CHECK-IN';
      case 'in_progress':
        return 'ĐANG KHÁM';
      case 'completed':
        return 'HOÀN THÀNH';
      case 'cancelled':
        return 'ĐÃ HỦY';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showEMRBottomSheet(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EMRFormWidget(
          appointment: appointment,
          calculateAge: _calculateAge,
          formatDateToDdMmYyyy: _formatDateToDdMmYyyy,
          onSuccess: () {
            fetchPatientHistory();
            setState(() {
              // Local update for appointment status
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: Stack(
        children: [
          // ================= BACKGROUND =================
          SizedBox(
            height: 240,
            width: double.infinity,
            child: Image.network(
              "https://images.unsplash.com/photo-1586773860418-d37222d8fce3",
              fit: BoxFit.cover,
            ),
          ),

          Container(
            height: 240,
            color: Colors.indigo.withOpacity(.55),
          ),

          // ================= CONTENT =================
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 120),
            child: Column(
              children: [
                // ================= HEADER CARD =================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AnimatedOpacity(
                            opacity: avatarOpacity,
                            duration: const Duration(milliseconds: 250),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.green.shade300,
                              backgroundImage:
                                  appointment.patientAvatar.isNotEmpty
                                      ? NetworkImage(
                                          appointment.patientAvatar,
                                        )
                                      : null,
                              child:
                                  appointment.patientAvatar.isEmpty
                                      ? Text(
                                          appointment.patientName.isNotEmpty
                                              ? appointment.patientName[0].toUpperCase()
                                              : "P",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Bệnh nhân",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  appointment.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF00A86B),
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  appointment.phone,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Ngày khám",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                appointment.date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "Giờ hẹn",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                appointment.time,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      _medicalAlertCard(),

                      const SizedBox(height: 16),

                      _infoSection(),

                      const SizedBox(height: 16),

                      _imageSection(
                        context,
                        appointment.imageUrl,
                      ),

                      const SizedBox(height: 16),

                      _historySection(),

                      const SizedBox(height: 20),

                      _medicalRecordButton(context),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context.pop();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Hoãn"),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  appointment.status == "cancelled"
                                      ? null
                                      : () async {
                                          final confirm =
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (_) => AlertDialog(
                                                      title:
                                                          const Text(
                                                            "Xác nhận",
                                                          ),
                                                      content:
                                                          const Text(
                                                            "Bạn có muốn hủy lịch không?",
                                                          ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () => Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child:
                                                              const Text(
                                                                "Không",
                                                              ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () => Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child:
                                                              const Text(
                                                                "Hủy",
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors.red,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                          if (confirm != true) return;

                                          try {
                                            await AppointmentApi
                                                .cancelAppointment(
                                                  appointment.id,
                                                );

                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Đã hủy lịch",
                                                  ),
                                                ),
                                              );

                                              context.pop(true);
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Hủy thất bại",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                side: const BorderSide(
                                  color: Colors.red,
                                ),
                                minimumSize:
                                    const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Hủy"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // ================= TOP BAR =================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(appointment.status),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          _getStatusLabel(appointment.status),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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

  // ================= SECTION =================

  Widget _medicalAlertCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF5722),
                  Color(0xFFFF1744),
                ],
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  "Thông Tin Y tế - Cần lưu ý",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _warningTile(
                  Icons.medical_information_outlined,
                  "Lý do khám",
                  widget.appointment.reason,
                  Colors.orange.shade50,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _warningTile(
                        Icons.history,
                        "Tiền sử bệnh",
                        widget.appointment.medicalHistory,
                        Colors.red.shade50,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _warningTile(
                        Icons.warning_amber,
                        "Dị ứng thuốc",
                        widget.appointment.allergies,
                        Colors.purple.shade50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningTile(
    IconData icon,
    String title,
    String value,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),

          const SizedBox(width: 8),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: value.isNotEmpty ? value : "Không có"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection() {
    return _sectionCard(
      title: "Thông tin Cuộc hẹn",
      gradient: const [
        Color(0xFF4A6CF7),
        Color(0xFF6A3DF0),
      ],
      child: Column(
        children: [
          _infoRow(
            Icons.calendar_today_outlined,
            "Ngày khám",
            widget.appointment.date,
          ),
          _infoRow(
            Icons.access_time,
            "Giờ hẹn",
            widget.appointment.time,
          ),
          _infoRow(
            Icons.person_outline,
            "Bệnh nhân",
            widget.appointment.patientName,
          ),
          _infoRow(
            Icons.phone_outlined,
            "Liên hệ",
            widget.appointment.phone,
          ),
        ],
      ),
    );
  }

  Widget _historySection() {
    return _sectionCard(
      title: "Lịch sử khám bệnh",
      gradient: const [
        Color(0xFF4C566A),
        Color(0xFF3B4252),
      ],
      child: loadingHistory
          ? const Center(child: CircularProgressIndicator())
          : patientHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Chưa có lịch sử khám bệnh trước đó",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              : Column(
                  children: patientHistory.map((rec) {
                    final parsedDate = rec['visitDate'] != null && rec['visitDate'].toString().isNotEmpty
                        ? MedicalRecordService.tryParseDateTime(rec['visitDate'].toString())
                        : null;
                    final dateStr = parsedDate != null ? DateFormat('dd/MM/yyyy').format(parsedDate) : 'N/A';
                    final doc = rec['doctorName'] ?? 'Bác sĩ';
                    final dept = rec['departmentName'] ?? '';
                    String diag = rec['diagnosis'] ?? rec['status'] ?? 'Bình thường';
                    if (diag == "Mắc bệnh (Y)" || diag.contains("Mắc bệnh (Y)")) {
                      diag = "Mắc bệnh tiểu đường";
                    } else if (diag == "Không mắc bệnh (N)" || diag.contains("Không mắc bệnh (N)")) {
                      diag = "Không mắc bệnh tiểu đường";
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _historyItem(
                        "Khám ${dept.isNotEmpty ? dept : 'tại phòng khám'} - $dateStr",
                        "BS. $doc • Chẩn đoán: $diag",
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _historyItem(String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: Colors.grey,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Color> gradient,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(colors: gradient),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),

          const SizedBox(width: 10),

          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageSection(
    BuildContext context,
    String image,
  ) {
    if (image.isEmpty) return const SizedBox.shrink();
    final List<String> images = image.split(',').where((s) => s.trim().isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      title: "Hình ảnh bệnh nhân cung cấp",
      gradient: const [
        Color(0xFFFF9800),
        Color(0xFFE91E63),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (ctx, idx) {
                final img = images[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Image.network(img),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.pop(_),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        img,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Click để xem ảnh kích thước lớn",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  Widget _medicalRecordButton(
    BuildContext context,
  ) {
    final status = widget.appointment.status;
    final isCompleted = status == 'completed';

    return ElevatedButton.icon(
      onPressed: isCompleted
          ? null
          : () => _showEMRBottomSheet(context, widget.appointment),
      icon: Icon(isCompleted ? Icons.check_circle : Icons.note_alt_outlined),
      label: Text(isCompleted ? "Đã nhập bệnh án" : "Thêm hồ sơ bệnh án"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCompleted ? Colors.grey : const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EMRFormWidget extends StatefulWidget {
  final Appointment appointment;
  final int Function(String) calculateAge;
  final String Function(String) formatDateToDdMmYyyy;
  final VoidCallback onSuccess;

  const _EMRFormWidget({
    required this.appointment,
    required this.calculateAge,
    required this.formatDateToDdMmYyyy,
    required this.onSuccess,
  });

  @override
  State<_EMRFormWidget> createState() => _EMRFormWidgetState();
}

class _EMRFormWidgetState extends State<_EMRFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  final _ureaController = TextEditingController();
  final _creatinineController = TextEditingController();
  final _hba1cController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  final _hdlController = TextEditingController();
  final _ldlController = TextEditingController();
  final _vldlController = TextEditingController();
  final _bmiController = TextEditingController();

  final _statusController = TextEditingController(text: "Không mắc bệnh");
  final _treatmentController = TextEditingController(
      text: "Điều chỉnh chế độ dinh dưỡng, giảm tinh bột và chất béo. Tập thể dục định kỳ và theo dõi sức khỏe.");
  bool _isSubmitting = false;
  bool _isAIPredicting = false;

  // CSV test data auto-fill
  List<List<dynamic>> _csvDataset = [];
  int _csvCurrentIndex = 0;
  String? _aiDiagnosisResult;
  String _aiSuggestedStatus = "Không mắc bệnh";

  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    try {
      final rawData = await rootBundle.loadString("assets/diabetes_test.csv");
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      if (listData.isNotEmpty) {
        listData.removeAt(0); // remove header
      }
      setState(() {
        _csvDataset = listData;
        _csvCurrentIndex = 0;
      });
    } catch (e) {
      debugPrint("Lỗi tải CSV: $e");
    }
  }

  void _fillNextFromCSV() {
    if (_csvDataset.isEmpty) return;
    setState(() {
      final row = _csvDataset[_csvCurrentIndex];
      
      // Update index
      _csvCurrentIndex = (_csvCurrentIndex + 1) % _csvDataset.length;

      // Map values
      _ureaController.text = row[2].toString();
      _creatinineController.text = row[3].toString();
      _hba1cController.text = row[4].toString();
      _cholesterolController.text = row[5].toString();
      _triglyceridesController.text = row[6].toString();
      _hdlController.text = row[7].toString();
      _ldlController.text = row[8].toString();
      _vldlController.text = row[9].toString();
      _bmiController.text = row[10].toString();
    });
  }

  String _formatResult(dynamic data) {
    if (data == null) return "";

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _formatResult(decoded);
      } catch (_) {
        return data.replaceAll(RegExp(r'[{}]'), '').trim();
      }
    }

    if (data is Map) {
      return data.entries.map((e) {
        if (e.key.toString().toLowerCase().contains("xác suất")) {
          return "${e.key}:\n${e.value}";
        }
        return "${e.key}: ${e.value}";
      }).join("\n\n");
    }
    if (data is List) {
      return data.map((e) => _formatResult(e)).join("\n");
    }

    return data.toString();
  }

  @override
  void dispose() {
    _statusController.dispose();
    _ureaController.dispose();
    _creatinineController.dispose();
    _hba1cController.dispose();
    _cholesterolController.dispose();
    _triglyceridesController.dispose();
    _hdlController.dispose();
    _ldlController.dispose();
    _vldlController.dispose();
    _bmiController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _runAIPrediction() async {
    if (_ureaController.text.isEmpty ||
        _creatinineController.text.isEmpty ||
        _hba1cController.text.isEmpty ||
        _cholesterolController.text.isEmpty ||
        _triglyceridesController.text.isEmpty ||
        _hdlController.text.isEmpty ||
        _ldlController.text.isEmpty ||
        _vldlController.text.isEmpty ||
        _bmiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ 9 chỉ số hóa sinh máu ở trên để AI phân tích."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAIPredicting = true);

    final double? urea = double.tryParse(_ureaController.text);
    final double? creatinine = double.tryParse(_creatinineController.text);
    final double? hba1c = double.tryParse(_hba1cController.text);
    final double? cholesterol = double.tryParse(_cholesterolController.text);
    final double? triglycerides = double.tryParse(_triglyceridesController.text);
    final double? hdl = double.tryParse(_hdlController.text);
    final double? ldl = double.tryParse(_ldlController.text);
    final double? vldl = double.tryParse(_vldlController.text);
    final double? bmi = double.tryParse(_bmiController.text);

    final int age = widget.calculateAge(widget.appointment.birthDate);
    final int safeAge = age > 0 ? age : 30;
    final String safeGender = widget.appointment.gender.isNotEmpty && 
        widget.appointment.gender.toLowerCase().contains("nam") ? "M" : "F";

    final patientData = {
      "Gender": safeGender,
      "AGE": safeAge,
      "Urea": urea ?? 0.0,
      "Cr": creatinine ?? 0.0,
      "HbA1c": hba1c ?? 0.0,
      "Chol": cholesterol ?? 0.0,
      "TG": triglycerides ?? 0.0,
      "HDL": hdl ?? 0.0,
      "LDL": ldl ?? 0.0,
      "VLDL": vldl ?? 0.0,
      "BMI": bmi ?? 0.0,
    };

    try {
      final response = await AIService.predictDisease(patientData);
      if (!mounted) return;

      String pred = response.toString();
      
      // Extract exact prediction class
      String exactPred = pred;
      final match = RegExp(r'Dự\s*đoán\s*[:=]\s*([^,}]+)', caseSensitive: false).firstMatch(pred);
      if (match != null) {
        exactPred = match.group(1)!.trim();
      } else {
        exactPred = pred.replaceAll(RegExp(r'[{}]'), '').trim();
      }

      // Convert exactPred format as requested
      if (exactPred == "Mắc bệnh (Y)" || exactPred == "Mắc bệnh" || exactPred.trim() == "Mắc bệnh") {
        exactPred = "Mắc bệnh tiểu đường";
      } else if (exactPred == "Không mắc bệnh (N)" || exactPred == "Không mắc bệnh" || exactPred.trim() == "Không mắc bệnh") {
        exactPred = "Không mắc bệnh tiểu đường";
      }

      setState(() {
        _aiDiagnosisResult = response;
        _aiSuggestedStatus = exactPred;
        _statusController.text = exactPred; // Auto-fill the exact AI prediction!
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("AI chẩn đoán: $pred -> Tự động điền '$exactPred'"),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi chạy chẩn đoán AI: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAIPredicting = false);
      }
    }
  }

  Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  final double? urea = double.tryParse(_ureaController.text);
  final double? creatinine = double.tryParse(_creatinineController.text);
  final double? hba1c = double.tryParse(_hba1cController.text);
  final double? cholesterol = double.tryParse(_cholesterolController.text);
  final double? triglycerides = double.tryParse(_triglyceridesController.text);
  final double? hdl = double.tryParse(_hdlController.text);
  final double? ldl = double.tryParse(_ldlController.text);
  final double? vldl = double.tryParse(_vldlController.text);
  final double? bmi = double.tryParse(_bmiController.text);

  final int calculatedAge = widget.calculateAge(widget.appointment.birthDate);
  final String formattedDate = widget.formatDateToDdMmYyyy(widget.appointment.date);

  try {
    final response = await MedicalRecordService.addMedicalRecord(
      patientId: widget.appointment.patientId,
      doctorId: widget.appointment.doctorId,
      patientName: widget.appointment.patientName,
      email: widget.appointment.patientEmail,
      examinationDate: formattedDate,
      examinationTime: widget.appointment.time,
      doctorName: widget.appointment.doctorName,
      departmentName: widget.appointment.departmentName.isNotEmpty
          ? widget.appointment.departmentName
          : widget.appointment.doctorSpecialty,
      gender: widget.appointment.gender.isNotEmpty ? widget.appointment.gender : "Nam",
      age: calculatedAge > 0 ? calculatedAge : 30,
      urea: urea,
      creatinine: creatinine,
      hba1c: hba1c,
      cholesterol: cholesterol,
      triglycerides: triglycerides,
      hdl: hdl,
      ldl: ldl,
      vldl: vldl,
      bmi: bmi,
      status: _statusController.text.trim(),
      symptoms: widget.appointment.reason.isNotEmpty
          ? widget.appointment.reason
          : "Không ghi nhận triệu chứng",
      treatment: _treatmentController.text.trim(),
    );

    if (!mounted) return;

    if (response == "success") {
      // Automatically complete the appointment status since medical record was added
      await AppointmentApi.updateStatus(
        id: widget.appointment.id,
        status: 'completed',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thêm bệnh án EMR & hoàn thành ca khám thành công!"),
          backgroundColor: Colors.teal,
        ),
      );
      
      widget.onSuccess();

      // 🟢 ĐÃ THÊM: Tự động hiển thị Hộp thoại hỏi Kê đơn thuốc
      final bool? confirmPrescription = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Bắt buộc bác sĩ phải chọn Có hoặc Không
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.medical_services_outlined, color: Colors.blue),
                SizedBox(width: 10),
                Text("Kê đơn thuốc", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text("Bệnh án đã được lưu. Bạn có muốn tiến hành kê đơn thuốc cho bệnh nhân này không?"),
            actions: [
              // Nút KHÔNG
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Không", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
              // Nút CÓ
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Có", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (confirmPrescription == true) {
        Navigator.pop(context);
        await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PrescriptionScreen(
        appointment: widget.appointment,
        diagnosis: _statusController.text.trim(), 
      ),
    ),
  );
       if (!mounted) return; 
        Navigator.pop(context, "open_prescription"); // Quay về hàng đợi với cờ mở đơn thuốc
      } else {
        // Bác sĩ chọn không kê đơn thuốc -> Quay lại màn hình cũ như bình thường
        Navigator.pop(context); // Close bottom sheet
        Navigator.pop(context, true); // Go back to queue with refresh flag
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $response"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Lỗi xảy ra: $e"),
        backgroundColor: Colors.redAccent,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final age = widget.calculateAge(appointment.birthDate);
    final gender = appointment.gender.isNotEmpty ? appointment.gender : "Chưa xác định";

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_add, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "Nhập Hồ Sơ Bệnh Án EMR",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Basic Info Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "BỆNH NHÂN",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appointment.patientName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildDemographicText("Giói tính", gender),
                          const SizedBox(width: 16),
                          _buildDemographicText("Tuổi", age > 0 ? "$age tuổi" : "30 tuổi (Mặc định)"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Chỉ số xét nghiệm hóa sinh máu",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        TextButton.icon(
                          onPressed: _fillNextFromCSV,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: Text(
                            _csvDataset.isEmpty
                                ? "Mẫu CSV"
                                : "${_csvCurrentIndex + 1}/${_csvDataset.length}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 2-Column Responsive Layout using Column + Rows to prevent vertical stretching
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNumericField(_ureaController, "Urea", "mmol/L")),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumericField(_creatinineController, "Cr (Creatinine)", "µmol/L")),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNumericField(_hba1cController, "HbA1c", "%")),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumericField(_cholesterolController, "Cholesterol", "mmol/L")),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNumericField(_triglyceridesController, "TG (Triglycerides)", "mmol/L")),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumericField(_hdlController, "HDL", "mmol/L")),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNumericField(_ldlController, "LDL", "mmol/L")),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumericField(_vldlController, "VLDL", "mmol/L")),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNumericField(_bmiController, "BMI", "kg/m²")),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // AI Predict Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAIPredicting ? null : _runAIPrediction,
                            icon: _isAIPredicting 
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, color: Colors.white),
                            label: Text(_isAIPredicting ? "AI đang phân tích..." : "Chẩn đoán bệnh bằng AI", style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_aiDiagnosisResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _aiDiagnosisResult.toString().contains("Không")
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _aiDiagnosisResult.toString().contains("Không")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _aiDiagnosisResult.toString().contains("Không")
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: _aiDiagnosisResult.toString().contains("Không")
                                      ? Colors.green
                                      : Colors.red,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatResult(_aiDiagnosisResult),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                      color: _aiDiagnosisResult.toString().contains("Không")
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Gợi ý chẩn đoán: $_aiSuggestedStatus",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _aiDiagnosisResult.toString().contains("Không")
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _statusController.text = _aiSuggestedStatus;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Đã điền kết quả AI '$_aiSuggestedStatus' vào chẩn đoán lâm sàng"),
                                        backgroundColor: Colors.teal,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: const Text(
                                    "Điền kết quả AI",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _aiDiagnosisResult.toString().contains("Không")
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Diagnostic status free text field
                    TextFormField(
                      controller: _statusController,
                      decoration: InputDecoration(
                        labelText: "Kết luận / Chẩn đoán lâm sàng",
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _statusController.clear();
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Không được bỏ trống kết luận";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Treatment/Phác đồ điều trị input field
                    TextFormField(
                      controller: _treatmentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Phác đồ điều trị / Lời khuyên bác sĩ",
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _treatmentController.clear();
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Không được bỏ trống phác đồ điều trị";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Hủy bỏ"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text("Lưu bệnh án", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemographicText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildNumericField(TextEditingController controller, String label, String unit) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: "$label ($unit)",
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Nhập số";
        }
        if (double.tryParse(value.trim()) == null) {
          return "Sai số";
        }
        return null;
      },
    );
  }
}