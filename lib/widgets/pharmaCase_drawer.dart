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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kMenuBgColor,
      elevation: 0, // Loại bỏ đổ bóng nặng nề để tạo cảm giác phẳng liền mạch với body
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Giữ vuông vắn theo trục bên trái màn hình
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
                // Khối vuông chứa Logo Icon bo tròn phẳng
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15), // Xanh cyan dịu nhẹ từ logo gốc
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded, 
                    color: Color(0xFF0284C7), 
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Tên hệ thống phân cấp text rõ ràng
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
                  route: "/pharma-case/dashboard",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.medication_liquid_outlined,
                  title: "Quản lý kho thuốc",
                  route: "/pharma-case/medicine-stock",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: "Đơn thuốc chờ",
                  route: "/pharma-case/pendin-prescriptions",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: "Cấp phát thuốc",
                  route: "/pharma-case/waiting-list",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business_outlined,
                  title: "Nhà cung cấp",
                  route: "/pharma-case/payments",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.badge_outlined,
                  title: "Hồ sơ của tôi",
                  route: "/pharma-case/medical-records",
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(color: kBorderColor, height: 1),
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Cài đặt",
                  route: "/pharma-case/settings",
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: "Đăng xuất",
                  route: "/pharma-case/logout",
                  isLogout: true,
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

    // Phối màu dựa trên trạng thái active
    final activeTextColor = isLogout ? const Color(0xFFEF4444) : kSelectedText;
    final inactiveTextColor = isLogout ? const Color(0xFFF87171) : kTextSecondary;
    final activeIconColor = isLogout ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    final inactiveIconColor = isLogout ? const Color(0xFFF87171) : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // Tạo khoảng cách thở giữa các thẻ menu
      child: ListTile(
        horizontalTitleGap: 12,
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // Bo góc nhẹ cho dòng được chọn giống kiến trúc thiết kế mới
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
        tileColor: isSelected ? kSelectedBg : Colors.transparent, // Nền xám nhạt tinh giản phẳng
        onTap: () {
          context.go(route);
        },
      ),
    );
  }
}