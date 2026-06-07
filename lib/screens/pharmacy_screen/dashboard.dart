import 'package:flutter/material.dart';
import '../../widgets/pharmacase_drawer.dart';

class PharmaCareDashboardScreen extends StatelessWidget {
  const PharmaCareDashboardScreen({super.key});

  static const Color kAppBarColor = Color(0xFF3EA6E9); //
  static const Color kTextBlue = Color(0xFF3EA6E9);    //
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    // ---- LOGIC TÍNH CÂU CHÀO REAL-TIME ----
    final int currentHour = DateTime.now().hour;
    String greetingText = 'Chào mừng Dược sĩ!';

    if (currentHour >= 5 && currentHour < 11) {
      greetingText = 'Chào buổi sáng, Dược sĩ!';
    } else if (currentHour >= 11 && currentHour < 14) {
      greetingText = 'Chào buổi trưa, Dược sĩ!';
    } else if (currentHour >= 14 && currentHour < 18) {
      greetingText = 'Chào buổi chiều, Dược sĩ!';
    } else {
      greetingText = 'Chào buổi tối, Dược sĩ!';
    }

    return Scaffold(
      backgroundColor: kBgColor,
      // ================= 1. APPBAR (GIỮ NGUYÊN TỪ MẪU) =================
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PharmaCare System",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                Text(
                  "Hệ thống quản lý nhà thuốc thông minh",
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white, size: 22),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text('DS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kAppBarColor)),
                ),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dược sĩ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const PharmaCaseDrawer(selectedMenu: "Tổng quan"),
      
      // ================= BODY CHÍNH CÓ CHỨA PHẦN THÊM MỚI BÊN DƯỚI =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng tiêu đề câu chào Real-time
            Text(
              greetingText,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kTextBlue, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ngày 3/6/2026 • 18:06', // Khớp chuẩn xác ảnh mẫu
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Khối cảnh báo 1: Kho thuốc
            _buildAlertBox(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFDC2626),
              title: '⚠️ Cảnh báo kho thuốc',
              content: 'Có 3 loại thuốc sắp hết hoặc đã hết hàng. Vui lòng nhập thêm!',
              actionText: 'XEM CHI TIẾT',
              borderColor: const Color(0xFFFCA5A5),
              bgColor: const Color(0xFFFEF2F2),
            ),
            const SizedBox(height: 16),

            // Khối cảnh báo 2: Hạn sử dụng
            _buildAlertBox(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFD97706),
              title: '⏰ Cảnh báo hạn sử dụng',
              content: 'Có 1 loại thuốc sắp hết hạn. Kiểm tra ngay!',
              borderColor: const Color(0xFFFDE68A),
              bgColor: const Color(0xFFFFFBEB),
            ),
            const SizedBox(height: 32),

            // Ba thẻ tóm tắt số liệu hàng đầu
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildStatCard(
                  title: 'Tổng thuốc trong kho',
                  value: '7',
                  subText: '↗ +5 mặt hàng mới',
                  themeColor: const Color(0xFF0EA5E9),
                  icon: Icons.archive_outlined,
                ),
                _buildStatCard(
                  title: 'Đơn thuốc chờ',
                  value: '3',
                  subText: '🕒 Cần xử lý ngay',
                  themeColor: const Color(0xFFD97706),
                  icon: Icons.assignment_outlined,
                ),
                _buildStatCard(
                  title: 'Thuốc cần chú ý',
                  value: '4',
                  subText: '⚠ Cần xử lý',
                  themeColor: const Color(0xFFEF4444),
                  icon: Icons.report_problem_outlined,
                ),_buildStatCard(
                  title: 'Đã cấp hôm nay',
                  value: '4',
                  subText: ' Hoàn thành tốt',
                  themeColor: const Color(0xFFEF4444),
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ==================== PHẦN BỔ SUNG MỚI: HAI CỘT DANH SÁCH CHI TIẾT ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CỘT 1: THUỐC CẦN CHÚ Ý (Rộng hơn để chứa thông tin lô/hạn dùng)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('💊', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Text(
                                  'Thuốc cần chú ý',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Xem tất cả', style: TextStyle(color: kAppBarColor, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Danh sách 4 sản phẩm theo đúng mẫu ảnh thiết kế
                        _buildAttentionMedicineItem(
                          name: 'Amoxicillin 250mg (M002)',
                          subInfo: '⚠ Còn 30 viên • Lô: DHG2024002',
                          isCritical: false,
                        ),
                        _buildAttentionMedicineItem(
                          name: 'Vitamin C 1000mg (M003)',
                          subInfo: '🔴 Đã hết hàng - Cần nhập ngay',
                          isCritical: true,
                        ),
                        _buildAttentionMedicineItem(
                          name: 'Ibuprofen 400mg (M004)',
                          subInfo: '⏰ Hết hạn: 2024-07-10 • Lô: PC2023004',
                          isCritical: false,
                        ),
                        _buildAttentionMedicineItem(
                          name: 'Aspirin 100mg (M007)',
                          subInfo: '⚠ Còn 25 viên • Lô: PC2024007',
                          isCritical: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // CỘT 2: ĐƠN THUỐC MỚI NHẤT
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            const Text(
                              'Đơn thuốc mới nhất',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            // Tag số lượng đơn chờ nhỏ màu cam
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('3 chờ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Danh sách đơn thuốc khẩn cấp và bình thường
                        _buildPrescriptionItem(
                          code: 'RX001',
                          patientName: 'Nguyễn Văn An',
                          doctor: 'BS. Trần Thị Hoa • 2 thuốc',
                          isUrgent: true,
                        ),
                        _buildPrescriptionItem(
                          code: 'RX002',
                          patientName: 'Trần Thị Bình',
                          doctor: 'BS. Lê Văn Nam • 2 thuốc',
                          isUrgent: false,
                        ),
                        _buildPrescriptionItem(
                          code: 'RX004',
                          patientName: 'Phạm Thị Dung',
                          doctor: 'BS. Trần Thị Hoa • 1 thuốc',
                          isUrgent: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ==================== COMPONENT WIDGETS PHỤ TRỢ BÊN BÁN THUỐC ====================

  // Hàng item của danh sách Thuốc cần chú ý
  Widget _buildAttentionMedicineItem({
    required String name,
    required String subInfo,
    required bool isCritical,
  }) {
    final cardBgColor = isCritical ? const Color(0xFFFDF2F2) : const Color(0xFFFFFBEB); // Hồng đỏ hoặc Vàng cam nhạt
    final iconData = isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
    final iconColor = isCritical ? const Color(0xFFEF4444) : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(iconData, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subInfo, style: TextStyle(color: iconColor.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Text(
            'NHẬP HÀNG',
            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3),
          )
        ],
      ),
    );
  }

  // Khối kén item đại diện Đơn thuốc
  Widget _buildPrescriptionItem({
    required String code,
    required String patientName,
    required String doctor,
    required bool isUrgent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFEF9C3).withOpacity(0.6) : Colors.white, // Nền vàng nhẹ nếu Khẩn
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? const Color(0xFFEAB308) : kBorderColor, width: isUrgent ? 1.5 : 1), // Viền cam đậm nếu Khẩn
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Khẩn', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('BN: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          Text(doctor, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  // (Giữ nguyên các hàm _buildAlertBox và _buildStatCard cũ của bạn...)
  Widget _buildAlertBox({required IconData icon, required Color iconColor, required String title, required String content, String? actionText, required Color borderColor, required Color bgColor}) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: 1.5)), child: Row(children: [Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))), const SizedBox(height: 4), Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500))])), if (actionText != null) ...[const SizedBox(width: 12), TextButton(onPressed: () {}, child: Text(actionText, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13)))]]));
  }
  Widget _buildStatCard({required String title, required String value, required String subText, required Color themeColor, required IconData icon}) {
    return Container(width: 260, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500))), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20))]), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(subText, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500))]));
  }
}