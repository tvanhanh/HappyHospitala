import 'package:flutter/material.dart';
// Import các trang con độc lập vào đây:
import 'profile_page.dart';
import 'printer_page.dart';
import 'system_page.dart';
import 'security_page.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  String selectedSubMenu = "Máy in"; // Menu đang kích hoạt

  // Hàm chuyển đổi Widget hiển thị linh hoạt dựa trên menu đã chọn
  Widget _renderBodyContent() {
    switch (selectedSubMenu) {
      case 'Hồ sơ':
        return const ProfilePage(); 
      case 'Máy in':
        return const PrinterPage(); 
      case 'Hệ thống':
        return const SystemPage(); 
      case 'Bảo mật':
        return const SecurityPage(); 
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 650,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header Tiêu đề cài đặt
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.computer_outlined, color: Colors.black87, size: 22),
                    SizedBox(width: 12),
                    Text('Cài đặt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Nội dung chia 2 bên rõ ràng
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MENU BÊN TRÁI
                Container(
                  width: 210,
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF1F5F9)))),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    children: [
                      _buildMenuLink('Hồ sơ', Icons.person_outline),
                      _buildMenuLink('Máy in', Icons.print_outlined),
                      _buildMenuLink('Hệ thống', Icons.desktop_windows_outlined),
                      _buildMenuLink('Bảo mật', Icons.lock_outline),
                    ],
                  ),
                ),

                // NỘI DUNG HIỂN THỊ TRANG CON BÊN PHẢI
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _renderBodyContent(), // Đã tối ưu nạp Widget động từ bên ngoài
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuLink(String title, IconData icon) {
    bool isSelected = selectedSubMenu == title;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () => setState(() => selectedSubMenu = title),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF070412) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : Colors.black87, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}