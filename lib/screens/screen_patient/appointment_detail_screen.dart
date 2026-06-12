import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
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

  String _formatBirthDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == 'null') return 'Chưa cập nhật';
    if (dateStr.contains('T')) {
      return dateStr.split('T')[0];
    }
    return dateStr;
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
        return "ĐÃ HỦY";
      default:
        return status.toUpperCase();
    }
  }

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

  String _formatCurrency(double amount) {
    return "${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  String _paymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tiền mặt';
      case 'insurance':
        return 'Bảo hiểm y tế';
      case 'vnpay':
        return 'VNPAY';
      case 'momo':
        return 'Ví MoMo';
      case 'banking':
        return 'Chuyển khoản';
      default:
        return method.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final statusColor = _statusColor(appointment.status);
    final statusTxt = _statusText(appointment.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: Stack(
        children: [
          // ================= BACKGROUND BANNER =================
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900.withOpacity(0.6),
                  Colors.blue.shade900.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // ================= CONTENT =================
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 130),
            child: Column(
              children: [
                // ================= CARD CONTAINER =================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----- DOCTOR HEADER -----
                      Row(
                        children: [
                          AnimatedOpacity(
                            opacity: avatarOpacity,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
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
                                radius: 32,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: appointment.doctorAvatar.isNotEmpty
                                    ? NetworkImage(appointment.doctorAvatar)
                                    : null,
                                child: appointment.doctorAvatar.isEmpty
                                    ? const Icon(Icons.person, size: 32, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.doctorSpecialty.isNotEmpty
                                      ? appointment.doctorSpecialty.toUpperCase()
                                      : "BÁC SĨ CHUYÊN KHOA",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "BS: ${appointment.doctorName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.apartment_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        appointment.departmentName.isNotEmpty
                                            ? appointment.departmentName
                                            : "Phòng khám Happy Clinic",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFECEFF1)),
                      const SizedBox(height: 20),

                      // ----- SECTION: CLINICAL DETAILS -----
                      _buildSectionHeader(
                        title: "Thông tin Khám bệnh",
                        icon: Icons.assignment_outlined,
                        gradient: [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.calendar_today_outlined, "Ngày khám", appointment.date),
                      _buildInfoRow(Icons.access_time, "Giờ hẹn", appointment.time),
                      _buildInfoRow(Icons.room_outlined, "Địa điểm", "Happy Clinic - 317 Trần Đại Nghĩa, Đà Nẵng"),
                      const SizedBox(height: 24),

                      // ----- SECTION: PATIENT INFORMATION -----
                      _buildSectionHeader(
                        title: "Thông tin Bệnh nhân",
                        icon: Icons.person_outline,
                        gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person, "Họ tên", appointment.patientName),
                      _buildInfoRow(Icons.wc, "Giới tính", appointment.gender),
                      _buildInfoRow(Icons.badge_outlined, "Số CCCD", appointment.cccd.isNotEmpty ? appointment.cccd : 'Chưa cập nhật'),
                      _buildInfoRow(Icons.cake_outlined, "Ngày sinh", _formatBirthDate(appointment.birthDate)),
                      _buildInfoRow(Icons.phone_outlined, "Số điện thoại", appointment.phone),
                      _buildInfoRow(Icons.location_on_outlined, "Địa chỉ", appointment.address),
                      const SizedBox(height: 24),

                      // ----- SECTION: MEDICAL CLINICAL NOTES -----
                      _buildSectionHeader(
                        title: "Lưu ý Sức khỏe",
                        icon: Icons.healing_outlined,
                        gradient: [const Color(0xFFFF5F6D), const Color(0xFFFFC371)],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.description_outlined, "Lý do khám", appointment.reason),
                      _buildInfoRow(Icons.warning_amber_outlined, "Dị ứng", appointment.allergies.isNotEmpty ? appointment.allergies : 'Không'),
                      if (appointment.medicalHistory.isNotEmpty && appointment.medicalHistory != 'null')
                        _buildInfoRow(Icons.history, "Tiền sử bệnh", appointment.medicalHistory),
                      const SizedBox(height: 16),
                      _buildImageSection(context, appointment.imageUrl),
                      const SizedBox(height: 24),

                      // ----- SECTION: BILLING & PAYMENT -----
                      _buildSectionHeader(
                        title: "Chi tiết Thanh toán",
                        icon: Icons.payment_outlined,
                        gradient: [const Color(0xFF8A2387), const Color(0xFFE94057)],
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentDetailItem("Phí khám gốc", _formatCurrency(appointment.originalFee)),
                      _buildPaymentDetailItem("Số tiền được giảm", "- ${_formatCurrency(appointment.originalFee - appointment.finalFee)}", isPromo: true),
                      _buildPaymentDetailItem(
                        "Tổng tiền phải trả",
                        _formatCurrency(appointment.finalFee),
                        isTotal: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBadge(
                              label: "Phương thức",
                              value: _paymentMethodText(appointment.paymentMethod),
                              color: Colors.blue.shade800,
                              bgColor: Colors.blue.shade50,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBadge(
                              label: "Thanh toán",
                              value: appointment.isPaid ? "ĐÃ THANH TOÁN" : "CHƯA THANH TOÁN",
                              color: appointment.isPaid ? Colors.green : Colors.red,
                              bgColor: appointment.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // ----- ACTION BUTTON -----
                      if (appointment.status == "pending" || appointment.status == "confirmed")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Xác nhận"),
                                  content: const Text("Bạn có chắc chắn muốn hủy lịch hẹn này không?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(_, false),
                                      child: const Text("Không"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(_, true),
                                      child: const Text("Hủy lịch", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              try {
                                await AppointmentApi.cancelAppointment(appointment.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đã hủy lịch hẹn thành công")),
                                  );
                                  context.pop(true);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Hủy lịch hẹn thất bại, vui lòng thử lại")),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                            label: const Text(
                              "Hủy lịch hẹn này",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // ================= CUSTOM APP BAR =================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusTxt,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
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

  // ================= CUSTOM WIDGETS =================

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradient),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13.5),
                children: [
                  TextSpan(
                    text: "$title:  ",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailItem(String label, String value, {bool isPromo = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14.5 : 13.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2C3E50) : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13.5,
              fontWeight: isTotal || isPromo ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? Colors.blue.shade700
                  : isPromo
                      ? Colors.green.shade600
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required String value, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: color.withOpacity(0.8), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, String imageUrls) {
    if (imageUrls.isEmpty || imageUrls == 'null') return const SizedBox.shrink();
    final List<String> images = imageUrls.split(',').where((s) => s.trim().isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hình ảnh triệu chứng:",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
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
        ],
      ),
    );
  }
}
