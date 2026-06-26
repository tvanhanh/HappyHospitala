import 'package:flutter/material.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';

class PharmacistProfileScreen extends StatefulWidget {
  const PharmacistProfileScreen({super.key});

  @override
  State<PharmacistProfileScreen> createState() => _PharmacistProfileScreenState();
}

class _PharmacistProfileScreenState extends State<PharmacistProfileScreen> {
  // Bảng màu thương hiệu hệ thống PharmaCare
  static const Color kPrimaryBlue = Color(0xFF3EA6E9); 
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0);

  // Khai báo các biến trạng thái điều khiển cho phần Cài đặt hệ thống
  bool _alertStock = true;
  bool _alertExpiry = true;
  bool _aiInteraction = true;
  bool _blockchainLog = false;
  bool _autoPrintLabel = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      // ================= APPBAR ĐỒNG BỘ HỆ THỐNG =================
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PharmaCare System", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text("Hệ thống quản lý nhà thuốc thông minh", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white, size: 22), onPressed: () {}),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Text('DS', style: TextStyle(fontSize: 11, color: kPrimaryBlue, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const PharmaCaseDrawer(selectedMenu: "Hồ sơ cá nhân"),
      
      // ================= THÂN TRANG HỒ SƠ & CÀI ĐẶT =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng Tiêu đề Trang
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ sơ của tôi',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
                ),
                SizedBox(height: 6),
                Text(
                  'Quản lý thông tin cá nhân và cài đặt cấu hình hệ thống',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Bố cục chia hai cột lớn (Hồ sơ bên trái - Cài đặt bên phải)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CỘT 1: THÔNG TIN CÁ NHÂN & CHUYÊN MÔN (Chiếm tỷ lệ 2/5)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Khối thẻ Avatar tổng quan
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorderColor),
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFFE0F2FE),
                              child: Text(
                                'B',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nguyễn Thị B',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dược sĩ',
                              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            // Tag trạng thái Đang hoạt động
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Đang hoạt động',
                                style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Khối thông tin chi tiết liên hệ và chứng chỉ hành nghề
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin liên hệ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('📧 Email:', 'nguyenthib@hospital.com'),
                            _buildInfoRow('📱 Điện thoại:', '+84 901 234 567'),
                            _buildInfoRow('🏥 Cơ sở:', 'HappyClinic'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: kBorderColor),
                            ),
                            const Text(
                              'Thông tin chuyên môn',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Số CCHN:', '012345/BYT-CCHN'),
                            _buildInfoRow('Ngày cấp:', '15/10/2020'),
                            _buildInfoRow('Nơi cấp:', 'Bộ Y Tế'),
                            _buildInfoRow('Trình độ:', 'Dược sĩ Đại học'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // CỘT 2: CÀI ĐẶT HỆ THỐNG (Chiếm tỷ lệ 3/5)
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
                        const Text(
                          'Cài đặt hệ thống',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tùy chỉnh tính năng nâng cao khi xử lý thuốc và cấp phát đơn hàng',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),
                        
                        // 1. Cấu hình cảnh báo hết thuốc
                        _buildSettingSwitchTile(
                          icon: Icons.inventory_2_outlined,
                          title: 'Cảnh báo thuốc sắp hết',
                          subtitle: 'Nhận thông báo hệ thống khi số lượng thuốc giảm dưới ngưỡng tối thiểu.',
                          value: _alertStock,
                          onChanged: (val) => setState(() => _alertStock = val),
                        ),
                        
                        // 2. Cấu hình cảnh báo hạn dùng
                        _buildSettingSwitchTile(
                          icon: Icons.running_with_errors_outlined,
                          title: 'Cảnh báo hạn sử dụng',
                          subtitle: 'Tự động thông báo danh sách thuốc chuẩn bị hết hạn trước 30 ngày.',
                          value: _alertExpiry,
                          onChanged: (val) => setState(() => _alertExpiry = val),
                        ),
                        
                        // 3. Cấu hình kiểm tra AI tương tác thuốc
                        _buildSettingSwitchTile(
                          icon: Icons.psychology_outlined,
                          title: 'Kiểm tra tương tác thuốc (AI)',
                          subtitle: 'Sử dụng trợ lý AI quét phân tích xung đột biệt dược khi duyệt đơn phát thuốc.',
                          value: _aiInteraction,
                          onChanged: (val) => setState(() => _aiInteraction = val),
                        ),
                        
                        // 4. Cấu hình lưu trữ Blockchain
                        _buildSettingSwitchTile(
                          icon: Icons.grid_view_rounded,
                          title: 'Lưu trữ Blockchain',
                          subtitle: 'Mã hóa và lưu trữ chuỗi băm (hash) đơn thuốc lên mạng Blockchain bảo mật.',
                          value: _blockchainLog,
                          onChanged: (val) => setState(() => _blockchainLog = val),
                        ),
                        
                        // 5. Cấu hình in nhãn tự động
                        _buildSettingSwitchTile(
                          icon: Icons.print_outlined,
                          title: 'In nhãn thuốc tự động',
                          subtitle: 'Hệ thống ra lệnh cho máy in xuất nhãn dán hướng dẫn ngay sau khi hoàn tất cấp phát.',
                          value: _autoPrintLabel,
                          onChanged: (val) => setState(() => _autoPrintLabel = val),
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

  // Widget dòng thông tin hiển thị dạng nhãn phẳng gọn gàng
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Widget xây dựng khối Toggle chọn lựa bật/tắt (Switch Tile)
  Widget _buildSettingSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: kPrimaryBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: kPrimaryBlue,
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFFE2E8F0),
          )
        ],
      ),
    );
  }
}