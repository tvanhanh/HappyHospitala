import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:flutter_application_datlichkham/services/api_appointment.dart';
import 'package:go_router/go_router.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String role;
  final VoidCallback onUpdated;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.role,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);

    return GestureDetector(
      onTap: () {
        if (role == 'doctor') {
          context.push(
            '/doctor/appointments/appointment-detail',
            extra: appointment,
          );
        } else {
          context.push(
            '/home/appointments/appointment-detail',
            extra: appointment,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              children: [
                // AVATAR
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: appointment.doctorAvatar.isNotEmpty
                        ? NetworkImage(appointment.doctorAvatar)
                        : null,
                    child: appointment.doctorAvatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 PATIENT NAME (QUAN TRỌNG)
                      Text(
                        "👤 ${appointment.patientName}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 🧑‍⚕️ DOCTOR + SPECIALTY
                      Text(
                        "🧑‍⚕️ BS: ${appointment.doctorName} • ${appointment.doctorSpecialty}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 📅 TIME
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "${appointment.date} • ${appointment.time}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // STATUS
                _statusChip(appointment.status, statusColor),
              ],
            ),

            const SizedBox(height: 12),

            // ================= REASON =================
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ================= ACTION =================
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  // ================= STATUS CHIP =================
  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= ACTION =================
  Widget _buildActions(BuildContext context) {
    if (role == "patient") {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: appointment.status == "cancelled"
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      // Sử dụng dialogContext riêng
                      title: const Text("Xác nhận"),
                      content: const Text("Bạn có muốn huỷ lịch không?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text("Không"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            "Huỷ",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  // 1. Kiểm tra nếu không bấm "Huỷ" hoặc đóng dialog ngang xương
                  if (confirm != true) return;

                  // 2. Kiểm tra xem Widget còn hiển thị trên màn hình không trước khi dùng context
                  if (!context.mounted) return;

                  try {
                    await AppointmentApi.cancelAppointment(appointment.id);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã huỷ lịch thành công")),
                    );

                    // Có thể thêm logic load lại danh sách ở đây
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Huỷ thất bại, vui lòng thử lại")),
                    );
                  }
                },
          icon: const Icon(Icons.cancel_outlined),
          label: Text(
            appointment.status == "cancelled" ? "Đã huỷ" : "Huỷ lịch",
          ),
        ),
      );
    }
    // Trả về widget trống nếu không phải patient

    if (role == "doctor") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await AppointmentApi.updateStatus(
                    id: appointment.id,
                    status: "confirmed",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xác nhận")),
                  );
                  onUpdated();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Xác nhận"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppointmentApi.updateStatus(
                    id: appointment.id,
                    status: "in_progress",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đang khám")),
                  );
                  onUpdated();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text("Đang khám"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppointmentApi.updateStatus(
                    id: appointment.id,
                    status: "completed",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hoàn thành")),
                  );
                  onUpdated();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Hoàn thành"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppointmentApi.updateStatus(
                    id: appointment.id,
                    status: "cancelled",
                  );
                  onUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã huỷ")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Huỷ"),
              ),
            ],
          ),
        ],
      );
    }
    if (role == "admin") {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      );
    }

    return const SizedBox();
  }

  String _statusText(String status) {
    switch (status) {
      case "pending":
        return "CHỜ XÁC NHẬN";

      case "confirmed":
        return "ĐÃ XÁC NHẬN";

      case "in_progress":
        return "ĐANG KHÁM";

      case "completed":
        return "HOÀN THÀNH";

      case "cancelled":
        return "ĐÃ HUỶ";

      default:
        return status.toUpperCase();
    }
  }

  // ================= STATUS COLOR =================
  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;

      case "confirmed":
        return Colors.blue;

      case "in_progress":
        return Colors.purple;

      case "completed":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
