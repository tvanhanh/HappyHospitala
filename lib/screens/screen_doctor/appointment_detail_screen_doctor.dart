import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/emr_ai_form.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'PrescriptionScreen.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_aiService.dart';

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
  // 1. Đảm bảo có từ khóa 'async' ở đây
  
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // ĐÂY LÀ CÁCH GỌI CLASS FORM CỦA BẠN
        return EmrAiFormWidget(
          appointment: widget.appointment, // Truyền dữ liệu cần thiết
          calculateAge: _calculateAge, // Truyền hàm logic
          formatDateToDdMmYyyy: _formatDateToDdMmYyyy,
          onSuccess: () {
            fetchPatientHistory();
            setState(() {});
          },
        );
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

                            // CẢNH BÁO Y TẾ
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
                            const SizedBox(height: 32),

                            // TIMELINE
                            const Text("Lịch Sử Khám Bệnh",
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
                                final dateStr = rec['visitDate'] != null
                                    ? _formatDateToDdMmYyyy(
                                        rec['visitDate'].toString())
                                    : 'N/A';
                                final doc =
                                    rec['doctorName'] ?? 'Chưa cập nhật';
                                final isLast =
                                    index == patientHistory.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Column(
                                          children: [
                                            Container(
                                                width: 14,
                                                height: 14,
                                                margin: const EdgeInsets.only(
                                                    top: 4),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFF3B82F6),
                                                        width: 3),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: const Color(
                                                                  0xFF3B82F6)
                                                              .withOpacity(0.3),
                                                          blurRadius: 6)
                                                    ])),
                                            if (!isLast)
                                              Expanded(
                                                  child: Container(
                                                      width: 2,
                                                      color: const Color(
                                                          0xFFE2E8F0))),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 20),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                    color:
                                                        const Color(0xFF94A3B8)
                                                            .withOpacity(0.08),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 4))
                                              ]),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text("BS. $doc",
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              Color(0xFF334155),
                                                          fontSize: 15)),
                                                  Text(dateStr,
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFF94A3B8),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF1F5F9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .medical_information_rounded,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                        child: Text(
                                                            "${rec['diagnosis'] ?? 'Sức khỏe ổn định'}",
                                                            style: const TextStyle(
                                                                color: Color(
                                                                    0xFF475569),
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))),
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
                              }),
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
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (!isCompleted)
                                    BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8))
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: isCompleted
                                    ? null
                                    : () => _showEMRBottomSheet(context),
                                icon: Icon(isCompleted
                                    ? Icons.verified_rounded
                                    : Icons.edit_document),
                                label: Text(
                                    isCompleted
                                        ? "Bệnh án đã hoàn thành"
                                        : "Khám & Nhập Bệnh Án EMR",
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
}