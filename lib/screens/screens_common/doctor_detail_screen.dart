import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/booking_screen.dart';
import '../../services/api_doctors.dart';
import 'package:go_router/go_router.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  final String role;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
    required this.role,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  Map<String, dynamic>? doctor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDoctor();
  }

  Future<void> loadDoctor() async {
    final res = await DoctorService.getDoctorById(widget.doctorId);
    setState(() {
      doctor = res;
      isLoading = false;
    });
  }

  // ================= FORMAT PRICE =================
  String _formatPrice(dynamic price) {
    final p = int.tryParse(price.toString()) ?? 0;
    return p
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (doctor == null) {
      return const Scaffold(
        body: Center(child: Text("Không có dữ liệu bác sĩ")),
      );
    }

    final d = doctor!;
    final profile = d['profile'] ?? {};
    final avatar = profile['avatar'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Chi tiết bác sĩ"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (avatar != null &&
                            avatar.toString().isNotEmpty &&
                            Uri.tryParse(avatar)?.hasAbsolutePath == true)
                        ? NetworkImage(avatar)
                        : null,
                    child: (avatar == null || avatar.toString().isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    d['name'] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profile['specialty'] ?? "Chưa cập nhật",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile['workShift'] ?? "Full time",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= INFO CARD =================
            _infoCard(profile, d),

            const SizedBox(height: 20),

            // ================= DESCRIPTION =================
            _section("Giới thiệu"),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                profile['description'] ?? "Chưa có mô tả",
                style: const TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 20),

            // ================= BUTTON =================
            _buildActionButtons(widget.role),
          ],
        ),
      ),
    );
  }

  // ================= INFO CARD =================
  Widget _infoCard(Map<String, dynamic> profile, Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _row(Icons.phone, profile['phone']),
          _row(Icons.work, "${profile['experience'] ?? 0} năm kinh nghiệm"),
          _row(Icons.school, profile['degree']),
          _row(Icons.schedule, profile['workShift']),
          _priceRow(profile['price']),
          _row(Icons.email, d['email']),
        ],
      ),
    );
  }

  // ================= PRICE =================
  Widget _priceRow(dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.green),
          const SizedBox(width: 10),
          Text(
            price != null && price != ""
                ? "${_formatPrice(price)} VNĐ"
                : "Chưa cập nhật giá",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ================= ROW =================
  Widget _row(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text ?? "Chưa cập nhật")),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================= BUTTON =================
  Widget _buildActionButtons(String role) {
    if (role == "patient") {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.calendar_month),
              label: const Text("Đặt lịch khám"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingScreen(doctorId: widget.doctorId),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }
}
