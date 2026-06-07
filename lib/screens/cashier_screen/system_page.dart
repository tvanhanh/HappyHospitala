import 'package:flutter/material.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  // Trạng thái các cấu hình hệ thống
  bool isDarkMode = false;
  bool enableNotification = true;
  String currencyFormat = 'VND (đ)';
  String dateFormat = 'DD/MM/YYYY';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= PHẦN GIAO DIỆN =================
        const Text(
          'Giao diện',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),

        // 1. Switch Chế độ tối
        _buildSwitchTile(
          icon: Icons.wb_sunny_outlined,
          title: 'Chế độ tối',
          subtitle: 'Bật giao diện tối',
          value: isDarkMode,
          onChanged: (val) => setState(() => isDarkMode = val),
        ),

        // 2. Switch Thông báo
        _buildSwitchTile(
          icon: Icons.notifications_none_outlined,
          title: 'Thông báo',
          subtitle: 'Hiển thị thông báo hệ thống',
          value: enableNotification,
          onChanged: (val) => setState(() => enableNotification = val),
        ),
        
        const SizedBox(height: 24),

        // ================= PHẦN ĐỊNH DẠNG =================
        const Text(
          'Định dạng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 20),

        // 3. Dropdown Định dạng tiền tệ
        const Text(
          'Định dạng tiền tệ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: currencyFormat,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(),
          items: const [
            DropdownMenuItem(value: 'VND (đ)', child: Text('VND (đ)', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: 'USD (\$)', child: Text('USD (\$)', style: TextStyle(fontSize: 14))),
          ],
          onChanged: (val) => setState(() => currencyFormat = val!),
        ),
        const SizedBox(height: 20),

        // 4. Dropdown Định dạng ngày
        const Text(
          'Định dạng ngày',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: dateFormat,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(),
          items: const [
            DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: 'MM/DD/YYYY', child: Text('MM/DD/YYYY', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD', style: TextStyle(fontSize: 14))),
          ],
          onChanged: (val) => setState(() => dateFormat = val!),
        ),
        
        const SizedBox(height: 32),

        // Nút lưu cấu hình hệ thống
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('💾 Đã áp dụng cấu hình hệ thống thành công!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF070412),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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

  // Widget thiết kế Switch tùy biến theo ảnh mẫu
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Nền xám nhạt nhẹ bọc ngoài
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Transform.scale(
          scale: 0.85, // Thu nhỏ nút switch lại một chút cho tinh tế
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF070412), // Nền switch đen khi bật
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE2E8F0), // Nền switch xám khi tắt
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}