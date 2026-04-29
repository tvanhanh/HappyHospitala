import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  double avatarOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      double offset = _scrollController.offset;

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

    const clinicName = "Happy Hospital";
    const clinicAddress = "123 Lê Lợi, Tam Kỳ, Quảng Nam";
    const clinicRoom = "Phòng 03 - Khoa Da liễu";
    const hotline = "0905 123 456";

    final backgrounds = [
      "https://images.unsplash.com/photo-1586773860418-d37222d8fce3",
      "https://images.unsplash.com/photo-1579684385127-1ef15d508118",
      "https://images.unsplash.com/photo-1538108149393-fbbd81895907",
    ];

    final bg = backgrounds[DateTime.now().second % backgrounds.length];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          // ===== HEADER =====
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Image.network(bg, fit: BoxFit.cover),
          ),

          Container(
            height: 260,
            color: Colors.black.withOpacity(0.4),
          ),

          // ===== BACK BUTTON =====

          // ===== CONTENT =====
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 260),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 90, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _statusChip(appointment.status),
                  const SizedBox(height: 20),
                  _card("Thông tin phòng khám", [
                    _row(Icons.local_hospital, "Cơ sở", clinicName),
                    _row(Icons.location_on, "Địa chỉ", clinicAddress),
                    _row(Icons.meeting_room, "Phòng", clinicRoom),
                    _row(Icons.phone, "Hotline", hotline),
                  ]),
                  _card("Thông tin lịch khám", [
                    _row(Icons.calendar_today, "Ngày", appointment.date),
                    _row(Icons.access_time, "Giờ", appointment.time),
                    _row(Icons.person, "Bệnh nhân", appointment.patientName),
                    _row(Icons.phone, "SĐT", appointment.phone),
                  ]),
                  _card("Thông tin y tế", [
                    _row(Icons.medical_services, "Lý do", appointment.reason),
                    _row(Icons.history, "Tiền sử", appointment.medicalHistory),
                    _row(Icons.warning, "Dị ứng", appointment.allergies),
                  ]),
                  if (appointment.imageUrl.isNotEmpty)
                    _imageSection(context, appointment.imageUrl),
                  const SizedBox(height: 20),
                  _actions(context),
                ],
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                }),
          ),

          // ===== AVATAR CHUẨN =====
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: avatarOpacity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade200],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: appointment.doctorAvatar.isNotEmpty
                          ? NetworkImage(appointment.doctorAvatar)
                          : null,
                      child: appointment.doctorAvatar.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Lịch hẹn với BS: ${appointment.doctorName}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "confirmed":
        color = Colors.green;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _imageSection(BuildContext context, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ảnh tình trạng bệnh",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.network(url)),
              );
            },
            child: Image.network(url, height: 180, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.appointment.status == "cancelled"
          ? null
          : () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Xác nhận"),
                  content: const Text("Bạn có muốn huỷ lịch không?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Không"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Huỷ",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              try {
                await AppointmentApi.cancelAppointment(widget.appointment.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã huỷ lịch")),
                );

                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Huỷ thất bại")),
                );
              }
            },
      icon: const Icon(Icons.cancel),
      label: Text(
        widget.appointment.status == "cancelled" ? "Đã huỷ" : "Huỷ lịch",
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
