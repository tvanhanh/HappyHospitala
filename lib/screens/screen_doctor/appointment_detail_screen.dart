import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';

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
                                  appointment.doctorAvatar.isNotEmpty
                                      ? NetworkImage(
                                          appointment.doctorAvatar,
                                        )
                                      : null,
                              child:
                                  appointment.doctorAvatar.isEmpty
                                      ? const Text(
                                        "N",
                                        style: TextStyle(
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          "ĐÃ XÁC NHẬN",
                          style: TextStyle(
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
                  TextSpan(text: value),
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
      child: Column(
        children: [
          _historyItem(
            "Khám da liễu - 15/05/2024",
            "BS. Nguyễn Văn A • Chẩn đoán: Viêm da cơ địa nhẹ",
          ),
          const SizedBox(height: 14),
          _historyItem(
            "Khám tổng quát - 10/03/2024",
            "BS. Trần Thị B • Sức khỏe ổn định",
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: const Text("Xem tất cả lịch sử khám"),
          )
        ],
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
    return _sectionCard(
      title: "Hình ảnh bệnh nhân cung cấp",
      gradient: const [
        Color(0xFFFF9800),
        Color(0xFFE91E63),
      ],
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => Dialog(
                        child: Image.network(image),
                      ),
                );
              },
              child: Image.network(
                image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
    return ElevatedButton.icon(
      onPressed: () {
        context.push(
          '/doctor/create-medical-record',
          extra: widget.appointment,
          
        );
      },
      icon: const Icon(Icons.note_alt_outlined),
      label: const Text("Nhập kết quả khám"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A6CF7),
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