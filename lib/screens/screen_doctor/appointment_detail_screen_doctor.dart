import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/emr_ai_form.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/emr_skin_cancer_form.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'PrescriptionScreen.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_aiService.dart';
import '../screen_patient/chat_screen.dart';
import '../screen_patient/virtual_clinic_screen.dart';

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
  List<Map<String, dynamic>> patientHistory = [];
  bool loadingHistory = true;
  bool _isSubmitting = false;
  final TextEditingController _statusController = TextEditingController();
  int _activeTabIndex = 0;
  @override
  void initState() {
    super.initState();
    fetchPatientHistory();
  }
  @override
  void dispose() {
    _statusController.dispose(); 
    super.dispose();
  }

  Future<void> fetchPatientHistory() async {
    try {
      final records = await MedicalRecordService.getMedicalRecord();
      if (!mounted) return;
      setState(() {
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
      if (mounted) setState(() => loadingHistory = false);
    }
  }

  bool _isPast(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(dateStr);
      } catch (_) {}
      if (parsed == null) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          parsed = DateTime(year, month, day);
        }
      }
      if (parsed != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pDate = DateTime(parsed.year, parsed.month, parsed.day);
        return pDate.isBefore(today);
      }
    } catch (_) {}
    return false;
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
        if (year != null) return DateTime.now().year - year;
      }
      return 30; // Default fallback age
    }
  }
  String _formatDateToDdMmYyyy(String dateStr) {
    if (dateStr.isEmpty) return DateFormat('dd/MM/yyyy').format(DateTime.now());
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4)
            return "${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}";
          return "${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}";
        }
      }
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'checked_in':
        return const Color(0xFF10B981);
      case 'in_progress':
        return const Color(0xFF8B5CF6);
      case 'completed':
        return const Color(0xFF14B8A6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  void _showEMRBottomSheet(BuildContext context) {
    final specialtyStr = "${widget.appointment.departmentName} ${widget.appointment.doctorSpecialty}".toLowerCase();
    final isDermatology = specialtyStr.contains('da liễu') || specialtyStr.contains('da lieu') || specialtyStr.contains('dermatology');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (isDermatology) {
          return EmrSkinCancerFormWidget(
            appointment: widget.appointment,
            calculateAge: _calculateAge,
            formatDateToDdMmYyyy: _formatDateToDdMmYyyy,
            onSuccess: () {
              fetchPatientHistory();
              setState(() {});
            },
          );
        } else {
          return EmrAiFormWidget(
            appointment: widget.appointment,
            calculateAge: _calculateAge,
            formatDateToDdMmYyyy: _formatDateToDdMmYyyy,
            onSuccess: () {
              fetchPatientHistory();
              setState(() {});
            },
          );
        }
      },
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final ap = widget.appointment;
    final isCompleted = ap.status == 'completed';
    

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            decoration:
                BoxDecoration(color: const Color(0xFFF4F7FB), boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40)
            ]),
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ================= SLIVER APP BAR =================
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      backgroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                                "https://images.unsplash.com/photo-1579684385127-1ef15d508118",
                                fit: BoxFit.cover),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF0F172A).withOpacity(0.4),
                                    const Color(0xFF0F172A).withOpacity(0.95)
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              left: 24,
                              right: 24,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8))
                                        ]),
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundColor: const Color(0xFF1E293B),
                                      backgroundImage:
                                          ap.patientAvatar.isNotEmpty
                                              ? NetworkImage(ap.patientAvatar)
                                              : null,
                                      child: ap.patientAvatar.isEmpty
                                          ? const Icon(Icons.person_rounded,
                                              size: 40, color: Colors.white70)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: _getStatusColor(ap.status)
                                                  .withOpacity(0.2),
                                              border: Border.all(
                                                  color:
                                                      _getStatusColor(ap.status)
                                                          .withOpacity(0.5)),
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                          ap.status),
                                                      shape: BoxShape.circle)),
                                              const SizedBox(width: 6),
                                              Text(ap.status.toUpperCase(),
                                                  style: TextStyle(
                                                      color: _getStatusColor(
                                                          ap.status),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.5)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(ap.patientName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 26,
                                                height: 1.2)),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(
                                              Icons.phone_in_talk_rounded,
                                              size: 14,
                                              color: Colors.white70),
                                          const SizedBox(width: 6),
                                          Text(ap.phone,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500))
                                        ]),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          Icon(
                                              ap.appointmentType == 'online'
                                                  ? Icons.video_chat_rounded
                                                  : Icons.local_hospital_rounded,
                                              size: 14,
                                              color: Colors.white70),
                                          const SizedBox(width: 6),
                                          Text(
                                              ap.appointmentType == 'online'
                                                  ? "Tư vấn Online"
                                                  : "Khám trực tiếp tại phòng khám",
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500))
                                        ]),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // ================= NỘI DUNG CUỘN =================
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabBar(),
                            if (_activeTabIndex == 0) ...[
                              Row(
                                children: [
                                  Expanded(
                                      child: _modernInfoCard(
                                          Icons.calendar_month_rounded,
                                          "Ngày Khám",
                                          ap.date,
                                          const Color(0xFF3B82F6))),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _modernInfoCard(
                                          Icons.schedule_rounded,
                                          "Giờ Hẹn",
                                          ap.time,
                                          const Color(0xFFF59E0B))),
                                ],
                              ),
                              const SizedBox(height: 24),

                              if (ap.appointmentType == 'online') ...[
                                _buildDoctorPreVisitCard(context, ap),
                                const SizedBox(height: 24),
                              ],

                              // CẢNG BÁO Y TẾ
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8))
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                              width: 4,
                                              color: const Color(0xFFEF4444))),
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFFEF2F2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12)),
                                                    child: const Icon(
                                                        Icons
                                                            .monitor_heart_rounded,
                                                        color: Color(0xFFEF4444),
                                                        size: 20)),
                                                const SizedBox(width: 12),
                                                const Text(
                                                    "Lý do & Chú ý Lâm sàng",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(0xFF1E293B),
                                                        fontSize: 17)),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                                ap.reason.isEmpty
                                                    ? "Bệnh nhân không ghi chú triệu chứng ban đầu."
                                                    : ap.reason,
                                                style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 15,
                                                    height: 1.5)),
                                            const SizedBox(height: 20),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFE2E8F0))),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        const Text("Tiền sử bệnh",
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xFF64748B),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                            ap.medicalHistory
                                                                    .isEmpty
                                                                ? "Không"
                                                                : ap
                                                                    .medicalHistory,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF0F172A),
                                                                fontSize: 14))
                                                      ])),
                                                  Container(
                                                      width: 1,
                                                      height: 40,
                                                      color:
                                                          const Color(0xFFCBD5E1),
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16)),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        const Text("Dị ứng",
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xFF64748B),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                            ap.allergies.isEmpty
                                                                ? "Không"
                                                                : ap.allergies,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF0F172A),
                                                                fontSize: 14))
                                                      ])),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // DANH SÁCH ẢNH DO BỆNH NHÂN TẢI LÊN
                              _imageSection(context, ap.imageUrl),
                            ] else ...[
                              // TAB 2: Lịch sử khám cũ
                              const Text("Lịch Sử Khám Bệnh Trước Đây",
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B))),
                              const SizedBox(height: 20),
                              if (loadingHistory)
                                const Center(child: CircularProgressIndicator())
                              else if (patientHistory.isEmpty)
                                DottedBorder(
                                  color: const Color(0xFFE2E8F0),
                                  strokeWidth: 1.5,
                                  dashPattern: const [6, 4],
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20)),
                                    child: const Column(children: [
                                      Icon(Icons.history_toggle_off_rounded,
                                          size: 48, color: Color(0xFFCBD5E1)),
                                      SizedBox(height: 16),
                                      Text("Chưa có lịch sử khám trước đây.",
                                          style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15))
                                    ]),
                                  ),
                                )
                              else
                                ...List.generate(patientHistory.length, (index) {
                                  final rec = patientHistory[index];
                                  return _buildHistoryTimelineItem(rec, index == patientHistory.length - 1);
                                }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ================= BOTTOM BAR (GLASSMORPHISM) =================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          border: Border(
                              top: BorderSide(
                                  color: Colors.white.withOpacity(0.2))),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    const Color(0xFF0F172A).withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, -10))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ap.appointmentType == 'online' &&
                                !_isPast(ap.date) &&
                                (ap.status == 'confirmed' ||
                                 ap.status == 'checked_in' ||
                                 ap.status == 'in_progress')) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => VirtualClinicScreen(
                                        appointment: ap,
                                        role: 'doctor',
                                      ),
                                    ));
                                  },
                                  icon: const Icon(Icons.video_call_rounded),
                                  label: const Text(
                                    "Vào phòng khám ảo ngay",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 60),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (!isCompleted && !_isPast(ap.date))
                                      BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8))
                                  ],
                                ),
                              child: ElevatedButton.icon(
                                onPressed: isCompleted || _isPast(ap.date)
                                    ? null
                                    : () => _showEMRBottomSheet(context),
                                icon: Icon(isCompleted
                                    ? Icons.verified_rounded
                                    : (_isPast(ap.date) ? Icons.lock_outline_rounded : Icons.edit_document)),
                                label: Text(
                                    isCompleted
                                        ? "Bệnh án đã hoàn thành"
                                        : (_isPast(ap.date)
                                            ? "Lịch hẹn đã quá hạn khám"
                                            : "Khám & Nhập Bệnh Án EMR"),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCompleted
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF2563EB),
                                  foregroundColor: isCompleted
                                      ? const Color(0xFF94A3B8)
                                      : Colors.white,
                                  disabledForegroundColor:
                                      const Color(0xFF94A3B8),
                                  disabledBackgroundColor:
                                      const Color(0xFFE2E8F0),
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            if (!isCompleted && ap.status != 'cancelled') ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () async {
                                  await AppointmentApi.cancelAppointment(ap.id);
                                  if (mounted) context.pop(true);
                                },
                                style: TextButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: const Text("Hủy lịch hẹn này",
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorPreVisitCard(BuildContext context, Appointment ap) {
    final hasCompleted = ap.isPreVisitCompleted;
    if (!hasCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chưa Có Dữ Liệu Lâm Sàng",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Bệnh nhân chưa điền form khảo sát tiền lâm sàng cho cuộc hẹn trực tuyến này.",
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFB45309).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final double bmi = (ap.height > 0)
        ? (ap.weight / ((ap.height / 100) * (ap.height / 100)))
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDCFCE7), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Dữ Liệu Tiền Lâm Sàng (Pre-visit)",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Metrics
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _miniMetricDoctorCard("Chiều cao", "${ap.height.toInt()} cm", const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniMetricDoctorCard("Cân nặng", "${ap.weight.toInt()} kg", const Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _miniMetricDoctorCard("BMI", bmi.toStringAsFixed(1), const Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniMetricDoctorCard(
                        "Đường huyết",
                        "${ap.bloodSugar} mmol/L",
                        ap.bloodSugar >= 7.0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Questionnaire
                const Text(
                  "Khảo sát & Tiền sử từ bệnh nhân:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    ap.preVisitQuestionnaire.isEmpty
                        ? "Bệnh nhân không điền thông tin mô tả."
                        : ap.preVisitQuestionnaire,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                // Chat History Collapsible
                if (ap.preVisitChatHistory.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: const PageStorageKey('triage_chat_expansion'),
                      title: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4F46E5), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Xem lịch sử AI Triage (${ap.preVisitChatHistory.length} tin nhắn)",
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: ap.preVisitChatHistory.length,
                            itemBuilder: (ctx, idx) {
                              final msg = ap.preVisitChatHistory[idx];
                              final isUser = msg['role'] == 'user';
                              final text = msg['text'] ?? '';
                              final specialty = msg['specialtyName'] ?? '';

                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFFE0F2FE) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                                      bottomRight: Radius.circular(isUser ? 0 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isUser ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: isUser ? const Color(0xFF0369A1) : const Color(0xFF1E293B),
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (specialty.toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "💡 Gợi ý khoa: $specialty",
                                            style: const TextStyle(
                                              color: Color(0xFF92400E),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ]
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricDoctorCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF94A3B8).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
  
  

  Widget _imageSection(BuildContext context, String image) {
    if (image.isEmpty) return const SizedBox.shrink();
    final List<String> images =
        image.split(',').where((s) => s.trim().isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Hình Ảnh Đính Kèm",
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (ctx, idx) {
              final img = images[idx];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(10),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(img, fit: BoxFit.contain)),
                            Positioned(
                                top: 10,
                                right: 10,
                                child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        onPressed: () => Navigator.pop(_)))),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(img,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 140,
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey))),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, "Thông tin hiện tại", Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(1, "Lịch sử khám cũ", Icons.history_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineItem(Map<String, dynamic> rec, bool isLast) {
    final dateStr = rec['visitDate'] != null
        ? _formatDateToDdMmYyyy(rec['visitDate'].toString())
        : 'N/A';
    final doc = rec['doctorName'] ?? 'Chưa cập nhật';
    final dept = rec['departmentName'] ?? '';
    final symptoms = rec['symptoms'] ?? '';
    final diagnosis = rec['diagnosis'] ?? '';
    final treatment = rec['treatment'] ?? '';

    // Extract metrics
    final hba1c = rec['hba1c']?.toString() ?? '';
    final bmi = rec['bmi']?.toString() ?? '';
    final creatinine = rec['creatinine']?.toString() ?? '';
    final urea = rec['urea']?.toString() ?? '';
    final cholesterol = rec['cholesterol']?.toString() ?? '';
    
    final hasMetrics = hba1c.isNotEmpty || bmi.isNotEmpty || creatinine.isNotEmpty || urea.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF3B82F6),
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 6)
                        ])),
                if (!isLast)
                  Expanded(
                      child: Container(
                          width: 2,
                          color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF94A3B8).withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.grey.withOpacity(0.05))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BS. $doc",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  fontSize: 15),
                            ),
                            if (dept.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                dept,
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Triệu chứng
                  if (symptoms.isNotEmpty) ...[
                    _buildHistoryField("Triệu chứng lâm sàng", symptoms, Icons.sick_outlined),
                    const SizedBox(height: 10),
                  ],

                  // Chẩn đoán
                  _buildHistoryField(
                    "Chẩn đoán y khoa",
                    diagnosis.isNotEmpty ? diagnosis : "Sức khỏe ổn định",
                    Icons.assignment_turned_in_outlined,
                    valueColor: diagnosis.toLowerCase().contains("mắc bệnh") || diagnosis.toLowerCase().contains("nghi ngờ") || diagnosis.toLowerCase().contains("ác tính")
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981)
                  ),

                  // Chỉ số sinh hóa / AI Metrics
                  if (hasMetrics) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Chỉ số sinh hóa (AI Triage)",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (hba1c.isNotEmpty) _buildHistoryMetricBadge("HbA1c", "$hba1c%"),
                          if (bmi.isNotEmpty) _buildHistoryMetricBadge("BMI", bmi),
                          if (creatinine.isNotEmpty) _buildHistoryMetricBadge("Creatinine", creatinine),
                          if (urea.isNotEmpty) _buildHistoryMetricBadge("Urea", urea),
                          if (cholesterol.isNotEmpty) _buildHistoryMetricBadge("Chol.", cholesterol),
                        ],
                      ),
                    ),
                  ],

                  // Đơn thuốc & Phác đồ
                  if (treatment.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.medication_rounded, size: 14, color: Color(0xFF3B82F6)),
                              SizedBox(width: 6),
                              Text(
                                "Đơn thuốc & Phác đồ điều trị cũ",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            treatment,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildHistoryField(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF334155),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryMetricBadge(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E40AF),
        ),
      ),
    );
  }
}