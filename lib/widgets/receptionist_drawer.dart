import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const kPrimaryColor = Color(0xFF0D47A1);
const kTextColor = Color(0xFF333333);
const kSecondaryColor = Color(0xFF1976D2);

class ReceptionistDrawer extends StatelessWidget {
  final String selectedMenu;

  const ReceptionistDrawer({
    super.key,
    required this.selectedMenu,
  });

  // HÀM HIỂN THỊ DIALOG XÁC NHẬN ĐĂNG XUẤT
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 8),
              Text(
                "Xác nhận đăng xuất",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            "Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            // Nút Hủy bỏ
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng hộp thoại
              },
              child: const Text(
                "Hủy",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            // Nút Đồng ý Đăng xuất
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 1. Đóng hộp thoại trước
                
                // 2. TODO: Nếu bạn dùng Riverpod/SharedPreferences để xóa Token auth, hãy gọi ở đây.
                // Ví dụ: ref.read(authProvider.notifier).logout();

                // 3. Điều hướng về trang login bằng GoRouter
                context.go('/auth/login'); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              "Nguyễn Thị Lan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: const Text("Lễ tân"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: kPrimaryColor,
              ),
            ),
            decoration: const BoxDecoration(
              color: kSecondaryColor,
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                _item(
                  context,
                  Icons.dashboard,
                  "Tổng quan",
                  "/receptionist/dashboard",
                ),
                _item(
                  context,
                  Icons.people,
                  "Quản lý bệnh nhân",
                  "/receptionist/patient-management",
                ),
                _item(
                  context,
                  Icons.calendar_today,
                  "Quản lý lịch hẹn",
                  "/receptionist/appointment-management",
                ),
                _item(
                  context,
                  Icons.access_time,
                  "Danh sách chờ khám",
                  "/receptionist/waiting-list",
                ),
                _item(
                  context,
                  Icons.folder_shared,
                  "Hồ sơ bệnh án",
                  "/receptionist/medical-records",
                ),
                const Divider(),
                _item(
                  context,
                  Icons.notifications,
                  "Thông báo",
                  "/receptionist/notification",
                ),
                _item(
                  context,
                  Icons.settings,
                  "Cài đặt",
                  "/receptionist/settings",
                ),
                // MỤC ĐĂNG XUẤT ĐÃ ĐƯỢC CHỈNH LOGIC
                _item(
                  context,
                  Icons.logout_rounded,
                  "Đăng xuất",
                  "/receptionist/logout", 
                  isLogoutItem: true, // Đánh dấu đây là nút đăng xuất
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    bool isLogoutItem = false, // Thêm biến optional nhận biết nút đăng xuất
  }) {
    final selected = selectedMenu == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isLogoutItem 
            ? Colors.redAccent // Nếu là nút đăng xuất thì cho icon màu đỏ cho nổi bật
            : (selected ? kSecondaryColor : kPrimaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogoutItem 
              ? Colors.redAccent 
              : (selected ? kSecondaryColor : kTextColor),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: selected ? kSecondaryColor.withOpacity(0.08) : null,
      onTap: () {
        if (isLogoutItem) {
          // Nếu bấm vào Đăng xuất -> Hiện hộp thoại nhỏ xác nhận
          _showLogoutDialog(context);
        } else {
          // Các mục khác -> Chuyển trang bình thường
          context.go(route);
        }
      },
    );
  }
}