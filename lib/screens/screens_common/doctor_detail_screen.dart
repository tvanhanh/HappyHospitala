import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_doctors.dart';

// ── Design Tokens 2026 ─────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF2563EB);
const Color _kPrimaryDark = Color(0xFF1E3A8A);
const Color _kAccent = Color(0xFF38BDF8);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

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
        backgroundColor: _kBackground,
        body: Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
      );
    }

    if (doctor == null) {
      return Scaffold(
        backgroundColor: _kBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _kTextPrimary,
          elevation: 0.5,
          title: const Text("Chi tiết bác sĩ"),
        ),
        body: const Center(
          child: Text(
            "Không có dữ liệu bác sĩ",
            style: TextStyle(color: _kTextSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final d = doctor!;

    // Adaptive parsing to support both populated Doctor schema model and old User model
    final bool isNewFormat = d.containsKey('userId') && d['userId'] is Map;
    final String docId = d['_id']?.toString() ?? widget.doctorId;

    final Map<String, dynamic> userMap =
        isNewFormat ? (d['userId'] as Map<String, dynamic>) : d;

    final String name = userMap['fullName'] ?? userMap['name'] ?? 'Bác sĩ';
    final String email = userMap['email'] ?? '';
    final String phone = userMap['phoneNumber'] ?? userMap['phone'] ?? '';
    final String avatar = userMap['avatar'] ?? '';

    final String bio =
        d['bio'] ?? d['description'] ?? 'Chưa có giới thiệu tiểu sử.';

    // Specialty Name
    String specialtyName = d['specialty']?.toString() ?? '';
    if (specialtyName.isEmpty && d['specialtyId'] != null) {
      if (d['specialtyId'] is Map) {
        specialtyName = d['specialtyId']['name']?.toString() ?? '';
      }
    }
    if (specialtyName.isEmpty) {
      specialtyName = 'Chuyên khoa';
    }

    // Room number location
    String roomNum = '';
    String roomFloor = '';
    if (d['roomId'] != null) {
      if (d['roomId'] is Map) {
        roomNum = d['roomId']['roomNumber']?.toString() ?? '';
        roomFloor = d['roomId']['floor']?.toString() ?? '';
      }
    }

    // Experience years
    final dynamic expYears = d['experience_years'] ?? d['experience'] ?? 0;

    // Fee / Price
    final dynamic fee = d['consultationFee'] ?? d['price'] ?? 0;

    // Education list
    final List<dynamic> educationList =
        d['education'] is List ? d['education'] : [];

    // Certifications list
    final List<dynamic> certificationsList = d['certifications_urls'] is List
        ? d['certifications_urls']
        : (d['certifications'] is List ? d['certifications'] : []);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Chi tiết bác sĩ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── HEADER INFO CARD ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kPrimary.withOpacity(0.15), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                      image: DecorationImage(
                        image: NetworkImage(avatar.isNotEmpty
                            ? avatar
                            : 'https://cdn-icons-png.flaticon.com/512/3774/3774299.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          specialtyName,
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (roomNum.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.room_rounded,
                                  color: Colors.green, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                roomFloor.isNotEmpty
                                    ? "Phòng $roomNum (Tầng $roomFloor)"
                                    : "Phòng $roomNum",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── QUICK STATS ROW ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.history_edu_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: "$expYears năm",
                      label: "Kinh nghiệm",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      icon: Icons.monetization_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: "${_formatPrice(fee)}đ",
                      label: "Giá khám",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: _kPrimary,
                      value: "Hoạt động",
                      label: "Trạng thái",
                    ),
                  ),
                ],
              ),
            ),

            // ── BIOGRAPHY CARD ───────────────────────────────────────────────────
            _section("Giới thiệu"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kTextPrimary,
                  height: 1.5,
                ),
              ),
            ),

            // ── EDUCATION CARD ───────────────────────────────────────────────────
            _section("Học vấn & Bằng cấp"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: educationList.isEmpty
                  ? const Center(
                      child: Text(
                        "Chưa cập nhật thông tin học vấn.",
                        style: TextStyle(color: _kTextSecondary),
                      ),
                    )
                  : Column(
                      children: educationList.map<Widget>((edu) {
                        final degree = edu['degree']?.toString() ?? '';
                        final uni = edu['university']?.toString() ?? '';
                        final year = edu['year']?.toString() ?? '';
                        final isLast = educationList.last == edu;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Year
                            SizedBox(
                              width: 60,
                              child: Text(
                                year,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Line and Dot
                            Column(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: _kPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 48,
                                    color: _kPrimary.withOpacity(0.15),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    degree,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    uni,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),

            // ── CERTIFICATIONS CARD ──────────────────────────────────────────────
            if (certificationsList.isNotEmpty) ...[
              _section("Chứng chỉ & Chứng nhận"),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: certificationsList.map<Widget>((cert) {
                    final certUrl = cert.toString();
                    final isUrl = certUrl.startsWith('http') ||
                        certUrl.startsWith('https');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              color: Color(0xFFF59E0B), size: 20),
                        ),
                        title: Text(
                          isUrl ? "Chứng chỉ chuyên môn" : certUrl,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _kTextPrimary),
                        ),
                        subtitle: isUrl
                            ? Text(
                                certUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _kPrimary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline),
                              )
                            : null,
                        trailing: isUrl
                            ? const Icon(Icons.open_in_new_rounded,
                                size: 16, color: _kPrimary)
                            : null,
                        onTap: isUrl
                            ? () {
                                // optional action
                              }
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // ── CONTACT DETAILS CARD ─────────────────────────────────────────────
            _section("Thông tin liên hệ"),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _contactRow(Icons.email_outlined, "Email liên hệ", email),
                  const Divider(height: 24, thickness: 0.5),
                  _contactRow(Icons.phone_outlined, "Số điện thoại",
                      phone.isNotEmpty ? phone : "Chưa cập nhật"),
                ],
              ),
            ),

            const SizedBox(height: 100), // Spacing for sticky bottom button
          ],
        ),
      ),
      // Sticky bottom button layout
      bottomNavigationBar: widget.role == "patient"
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 20),
                label: const Text(
                  "Đặt lịch khám ngay",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  context.push('/booking/$docId');
                },
              ),
            )
          : null,
    );
  }

  // ─── STYLISH WIDGET UTILITIES ──────────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _kPrimary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _kTextSecondary, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
