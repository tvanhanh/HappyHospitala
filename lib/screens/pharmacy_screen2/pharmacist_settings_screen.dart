import 'package:flutter/material.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';
class PharmacistSettingsPage extends StatefulWidget {
  const PharmacistSettingsPage({super.key});

  @override
  State<PharmacistSettingsPage> createState() => _PharmacistSettingsPageState();
}

class _PharmacistSettingsPageState extends State<PharmacistSettingsPage> {
  // Hệ màu thương hiệu PharmaCare đồng bộ toàn hệ thống
  static const Color kHeaderBlue = Color(0xFF3EA6E9); 
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  // Trạng thái cấu hình của các nút Switch cài đặt hệ thống
  bool _canhBaoSapHet = true;
  bool _canhBaoHanDung = true;
  bool _kiemTraTuongTacAI = true;
  bool _luuBlockchain = true;
  bool _inNhanTuDong = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền xám nhạt cao cấp cho Desktop
      
      // ================= 1. HEADER HỆ THỐNG (TOP BAR) =================
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Row(
          children: [
            // Icon Logo hình hộp thuốc tròn
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF64B5F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PharmaCare System',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Hệ thống quản lý nhà thuốc thông minh',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Chuông thông báo có số 4 màu đỏ
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text(
                    '4',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          
          // Thẻ thông tin tài khoản Dược sĩ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF64B5F6),
                    child: Text('DS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dược sĩ', style: TextStyle(color: Colors.white, fontSize: 11)),
                      Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      
      // ================= 2. BODY CHI TIẾT CÀI ĐẶT =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            width: 1000, 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner thông tin Dược Sĩ bên trong trang
                _buildProfileHeader(),
                
                const Divider(color: kBorderColor, height: 1),

                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CỘT TRÁI: THÔNG TIN CHI TIẾT (Liên hệ & Chuyên môn)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(
                              title: 'Thông tin liên hệ',
                              icon: Icons.contact_mail_outlined,
                              children: [
                                _buildDetailRow('📧 Email', 'nguyenthib@hospital.com'),
                                _buildDetailRow('📱 Số điện thoại', '+84 901 234 567'),
                                _buildDetailRow('🏥 Cơ sở làm việc', 'Phòng khám ABC'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildInfoSection(
                              title: 'Thông tin chuyên môn',
                              icon: Icons.workspace_premium_outlined,
                              children: [
                                _buildDetailField(label: 'Số chứng chỉ hành nghề', value: 'CCHN-012345/BYT'),
                                _buildDetailField(label: 'Ngày cấp', value: '15/08/2022'),
                                _buildDetailField(label: 'Nơi cấp', value: 'Bộ Y Tế Việt Nam'),
                                _buildDetailField(label: 'Trình độ chuyên môn', value: 'Dược sĩ Đại học (BPharm)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 48),
                      
                      // Thanh chia dọc ngăn cách 2 khu vực
                      Container(width: 1, height: 520, color: kBorderColor),
                      
                      const SizedBox(width: 48),

                      // CỘT PHẢI: CÀI ĐẶT HỆ THỐNG (BẬT/TẮT TÍNH NĂNG)
                      Expanded(
                        flex: 5,
                        child: _buildSettingsSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE0F2FE),
            child: const Text(
              'B',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryBlue),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nguyễn Thị B',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Dược sĩ Lâm sàng', style: TextStyle(fontSize: 14, color: kTextMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: kSuccessGreen, size: 8),
                        SizedBox(width: 6),
                        Text('Đang hoạt động', style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: kTextMuted, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildDetailField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: Text(value, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.settings_suggest_outlined, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 8),
            Text('Cài đặt hệ thống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
          ],
        ),
        const SizedBox(height: 20),
        
        _buildSwitchTile(
          title: 'Cảnh báo thuốc sắp hết',
          subtitle: 'Nhận thông báo khi thuốc dưới ngưỡng tối thiểu',
          value: _canhBaoSapHet,
          onChanged: (val) => setState(() => _canhBaoSapHet = val),
        ),
        _buildSwitchTile(
          title: 'Cảnh báo hạn sử dụng',
          subtitle: 'Cảnh báo thuốc sắp hết hạn (30 ngày trước)',
          value: _canhBaoHanDung,
          onChanged: (val) => setState(() => _canhBaoHanDung = val),
        ),
        _buildSwitchTile(
          title: 'Kiểm tra tương tác thuốc (AI)',
          subtitle: 'Sử dụng AI để kiểm tra tương tác khi cấp phát',
          value: _kiemTraTuongTacAI,
          onChanged: (val) => setState(() => _kiemTraTuongTacAI = val),
        ),
        _buildSwitchTile(
          title: 'Lưu trữ Blockchain',
          subtitle: 'Lưu hash đơn thuốc lên Blockchain',
          value: _luuBlockchain,
          onChanged: (val) => setState(() => _luuBlockchain = val),
        ),
        _buildSwitchTile(
          title: 'In nhãn thuốc tự động',
          subtitle: 'Tự động in nhãn khi cấp phát thuốc hồ cài đặt',
          value: _inNhanTuDong,
          onChanged: (val) => setState(() => _inNhanTuDong = val),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? kPrimaryBlue.withOpacity(0.3) : kBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: kTextMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: kPrimaryBlue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}