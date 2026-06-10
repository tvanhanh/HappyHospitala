import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/admin_stats_provider.dart';
import '../../services/config.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kSecondary = Color(0xFF0D47A1);
const Color _kBgColor = Color(0xFFF4F7FA);

class StaffManagerScreen extends ConsumerStatefulWidget {
  const StaffManagerScreen({super.key});

  @override
  ConsumerState<StaffManagerScreen> createState() => _StaffManagerScreenState();
}

class _StaffManagerScreenState extends ConsumerState<StaffManagerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Trạng thái cho layout 3 cột
  String _selectedRole = 'receptionist';
  AppUser? _selectedUser; // Lưu trữ nhân viên đang được click xem chi tiết

  // ================= CÁC HÀM XỬ LÝ API (Giữ nguyên của bạn) =================
  Future<void> _createStaffAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': name,
        'email': email,
        'password': password,
        'role': _selectedRole, // Lấy role đang chọn
      }),
    );

    if (res.statusCode == 201) {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      ref.invalidate(usersProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tạo tài khoản thành công!'),
              backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${body['message']}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.patch(
      Uri.parse('$baseUrl/admin/users/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      ref.invalidate(usersProvider);
      if (mounted) {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(body['message']), backgroundColor: Colors.green),
        );
        // Reset chi tiết nếu đang xem người bị khóa
        if (_selectedUser?.id == id) setState(() => _selectedUser = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: _kBgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm Nhân Sự',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= CỘT 1: SIDEBAR LỌC ROLE (15%) =================
          Container(
            width: 220,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('PHÒNG BAN',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1.5)),
                ),
                _buildRoleTab('receptionist', 'Lễ Tân', Icons.person_outline),
                _buildRoleTab('cashier', 'Thu Ngân', Icons.point_of_sale),
                _buildRoleTab('pharmacy', 'Kho Thuốc', Icons.local_pharmacy),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),

          // ================= CỘT 2: DANH SÁCH NHÂN VIÊN (30%) =================
          Expanded(
            flex: 3,
            child: asyncUsers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (users) {
                final staffUsers =
                    users.where((u) => u.role == _selectedRole).toList();

                if (staffUsers.isEmpty) {
                  return const Center(
                      child: Text('Chưa có nhân viên nào trong nhóm này.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffUsers.length,
                  itemBuilder: (context, index) {
                    final user = staffUsers[index];
                    final isSelected = _selectedUser?.id == user.id;
                    final isLocked = user.status == 'inactive';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimary.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPrimary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(
                            () => _selectedUser = user), // Click để hiện Cột 3
                        leading: CircleAvatar(
                          backgroundColor: isLocked
                              ? Colors.red.withOpacity(0.1)
                              : _kPrimary.withOpacity(0.1),
                          child: Icon(Icons.person,
                              color: isLocked ? Colors.red : _kPrimary),
                        ),
                        title: Text(user.name,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        subtitle: Text(isLocked ? "Đã khóa" : "Hoạt động",
                            style: TextStyle(
                                color: isLocked ? Colors.red : Colors.green,
                                fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.grey, size: 20),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),

          // ================= CỘT 3: CHI TIẾT & KPI (55%) =================
          Expanded(
            flex: 5,
            child: _selectedUser == null
                ? const Center(
                    child: Text('Chọn một nhân viên bên trái để xem chi tiết',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : _buildStaffDetailPanel(_selectedUser!),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CỘT 1 ---
  Widget _buildRoleTab(String roleValue, String title, IconData icon) {
    final isSelected = _selectedRole == roleValue;
    return InkWell(
      onTap: () => setState(() {
        _selectedRole = roleValue;
        _selectedUser = null; // Reset cột 3 khi đổi tab
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(
                  color: isSelected ? _kPrimary : Colors.transparent,
                  width: 4)),
          color: isSelected ? _kPrimary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? _kPrimary : Colors.grey.shade600, size: 20),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(
                    color: isSelected ? _kPrimary : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CỘT 3 ---
  Widget _buildStaffDetailPanel(AppUser user) {
    final isLocked = user.status == 'inactive';

    return DefaultTabController(
      length: 3,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header Chi tiết
            Container(
              padding: const EdgeInsets.all(32),
              color: _kBgColor,
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 40,
                      backgroundColor: _kPrimary.withOpacity(0.2),
                      child: Text(user.name[0],
                          style: const TextStyle(
                              fontSize: 32,
                              color: _kPrimary,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(user.role.toUpperCase(),
                              style: TextStyle(
                                  color: _getRoleColor(user.role),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  // Nút khóa/Mở khóa ở ngay góc trên Cột 3
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isLocked ? Colors.green : Colors.red.shade50,
                      foregroundColor: isLocked ? Colors.white : Colors.red,
                      elevation: 0,
                    ),
                    icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                    label: Text(isLocked ? "Mở Khóa" : "Đình Chỉ"),
                    onPressed: () => _toggleUserStatus(user.id),
                  ),
                ],
              ),
            ),
            // Tabs cho phần Detail
            const TabBar(
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _kPrimary,
              tabs: [
                Tab(text: "Tổng quát"),
                Tab(text: "Hiệu suất (KPI)"),
                Tab(text: "Nhật ký (Audit Log)"),
              ],
            ),
            // Nội dung Tabs
            Expanded(
              child: TabBarView(
                children: [
                  Center(
                      child: Text(
                          "Thông tin cá nhân, bằng cấp chứng chỉ của ${user.name}")),
                  Center(
                      child: Text(
                          "Biểu đồ doanh thu/lượt khách do ${user.name} phục vụ")),
                  Center(
                      child: Text(
                          "Lịch sử giao dịch, chỉnh sửa kho thuốc được Hash Blockchain")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG THÊM MỚI (Đã thu gọn lại cho đẹp) ---
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Nhân Sự'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên')),
            const SizedBox(height: 16),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu tạm')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: _createStaffAccount,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: const Text('Tạo')),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'receptionist':
        return Colors.purple;
      case 'cashier':
        return Colors.orange;
      case 'pharmacy':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
