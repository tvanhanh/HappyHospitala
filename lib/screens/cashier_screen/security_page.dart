import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Trạng thái cấu hình phiên làm việc
  String selectedSessionTimeout = '15 phút';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= KHỐI 1: BẢO MẬT TÀI KHOẢN =================
          const Text(
            'Bảo mật tài khoản',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),

          _buildPasswordField(label: 'Mật khẩu hiện tại', hint: 'Nhập mật khẩu hiện tại'),
          _buildPasswordField(label: 'Mật khẩu mới', hint: 'Nhập mật khẩu mới'),
          _buildPasswordField(label: 'Xác nhận mật khẩu mới', hint: 'Nhập lại mật khẩu mới'),
          
          const SizedBox(height: 12),
          
          // Nút Đổi mật khẩu dẹt chuẩn UI mẫu
          OutlinedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔑 Đã cập nhật mật khẩu mới thành công!'), backgroundColor: Colors.green),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 40),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Đổi mật khẩu',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 24),

          // ================= KHỐI 2: PHIÊN LÀM VIỆC =================
          const Text(
            'Phiên làm việc',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),

          // Dropdown chọn thời gian tự động đăng xuất
          const Text(
            'Tự động đăng xuất sau',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedSessionTimeout,
            dropdownColor: Colors.white,
            decoration: _dropdownDecoration(),
            items: const [
              DropdownMenuItem(value: '15 phút', child: Text('15 phút', style: TextStyle(fontSize: 14))),
              DropdownMenuItem(value: '30 phút', child: Text('30 phút', style: TextStyle(fontSize: 14))),
              DropdownMenuItem(value: '60 phút', child: Text('60 phút', style: TextStyle(fontSize: 14))),
              DropdownMenuItem(value: 'Không tự động đăng xuất', child: Text('Không tự động đăng xuất', style: TextStyle(fontSize: 14))),
            ],
            onChanged: (val) => setState(() => selectedSessionTimeout = val!),
          ),
          
          const SizedBox(height: 20),

          // Thông tin phiên đăng nhập hiện tại bọc trong thẻ xám tinh tế
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // Nền xám nhạt đồng bộ các trang cấu hình
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phiên đăng nhập hiện tại',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Chấm xanh trạng thái đang hoạt động
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Đang hoạt động',
                      style: TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng nhập lúc: 08:00 - 03/06/2026', // Cập nhật đúng thời gian thực của hệ thống
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Nút lưu tổng thể cấu hình bảo mật
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('💾 Đã áp dụng cấu hình bảo mật thành công!'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF070412), // Nút đen chủ đạo
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ô nhập mật khẩu ẩn ký tự
  Widget _buildPasswordField({required String label, required String hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          TextFormField(
            obscureText: true, // Ẩn mật khẩu mật định
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF070412))),
            ),
          ),
        ],
      ),
    );
  }

  // Khung trang trí Dropdown đồng bộ
  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF070412))),
    );
  }
}