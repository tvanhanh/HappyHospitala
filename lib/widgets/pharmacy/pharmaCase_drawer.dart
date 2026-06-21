import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmaCaseDrawer extends StatelessWidget {
  final String selectedMenu;

  const PharmaCaseDrawer({
    super.key,
    required this.selectedMenu,
  });

  // Bảng màu phẳng, tinh tế chuẩn SaaS Healthcare
  static const Color kMenuBgColor = Colors.white;
  static const Color kTextPrimary = Color(0xFF1E293B);   // Đen xám đậm thanh lịch
  static const Color kTextSecondary = Color(0xFF64748B); // Xám chữ phụ
  static const Color kSelectedBg = Color(0xFFF1F5F9);    // Xám nhạt highlight điểm chọn
  static const Color kSelectedText = Color(0xFF0F172A);  // Chữ khi được active sẽ đậm và nổi bật
  static const Color kBorderColor = Color(0xFFE2E8F0);   // Đường kẻ mỏng tinh tế

  // 🟢 Hàm xử lý hiển thị Dialog xác nhận Đăng xuất
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc người dùng chọn Có hoặc Không
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 10),
              Text(
                'Xác nhận đăng xuất',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống PharmaCare không?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            // Nút Bỏ qua / Không
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Không',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Nút Đồng ý / Có
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Đóng hộp thoại xác nhận
                
                // 🛑 THỰC HIỆN LOGOUT THỰC TẾ Ở ĐÂY:
                // Ví dụ xóa Token, xóa SharedPreferences, clear AuthState...
                
                // Chuyển hướng về trang đăng nhập
                context.go('/auth/login'); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Có, đăng xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kMenuBgColor,
      elevation: 0, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, 
      ),
      child: Column(
        children: [
          // ================= NEW PREMIUM HEADER =================
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: kBorderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15), 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded, 
                    color: Color(0xFF0284C7), 
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PharmaCare",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kTextPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Hệ thống quản lý thông minh",
                        style: TextStyle(
                          fontSize: 11,
                          color: kTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= MENU ITEMS LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: "Tổng quan",
                  route: "/pharmacy/dashboard",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.medication_liquid_outlined,
                  title: "Quản lý kho thuốc",
                  route: "/pharmacy/medicine-stock",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: "Đơn thuốc chờ",
                  route: "/pharmacy/pending-prescriptions",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: "Nhập kho",
                  route: "/pharmacy/medicineimport",
                ),
                 _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: "Tồn kho",
                  route: "/pharmacy/inventory",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business_outlined,
                  title: "báo cáo",
                  route: "/pharmacy/report",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.badge_outlined,
                  title: "Hồ sơ của tôi",
                  route: "/pharmacy/profile",
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(color: kBorderColor, height: 1),
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Cài đặt",
                  route: "/pharmacy/settings",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: "Đăng xuất",
                  route: "/pharmacy/logout",
                  isLogout: true, // Đánh dấu thẻ logout
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget dòng menu cải tiến bo góc nhẹ chuẩn UI hiện đại
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    final isSelected = selectedMenu == title;

    final activeTextColor = isLogout ? const Color(0xFFEF4444) : kSelectedText;
    final inactiveTextColor = isLogout ? const Color(0xFFF87171) : kTextSecondary;
    final activeIconColor = isLogout ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    final inactiveIconColor = isLogout ? const Color(0xFFF87171) : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4), 
      child: ListTile(
        horizontalTitleGap: 12,
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? activeIconColor : inactiveIconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? activeTextColor : inactiveTextColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        tileColor: isSelected ? kSelectedBg : Colors.transparent, 
        onTap: () {
          // 🟢 ĐÃ SỬA LOGIC ONTAP: Nếu bấm đăng xuất thì hiện Dialog thay vì tự động chuyển trang
          if (isLogout) {
            _showLogoutConfirmationDialog(context);
          } else {
            context.go(route);
          }
        },
      ),
    );
  }
}