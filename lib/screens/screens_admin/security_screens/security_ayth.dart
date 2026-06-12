import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'create_account_screen.dart';

// --- PALETTE MÀU (AI & Blockchain Theme) ---
const Color kPrimaryColor = Color(0xFF1565C0); // Xanh Admin
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kActiveColor = Color(0xFF4CAF50);
const Color kInactiveColor = Color(0xFFE57373);
const Color kAdminColor = Color(0xFF673AB7); // Tím (Quyền lực/Blockchain)
const Color kDoctorColor = Color(0xFF00ACC1); // Cyan (Y tế)

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = []; // Danh sách để search
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // --- LOGIC API (Giữ nguyên) ---
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() {
        users = data;
        filteredUsers = data; // Khởi tạo danh sách lọc
      });
    } catch (e) {
      showSnackbar("Lỗi tải dữ liệu: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    });
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleUserActive(String id, String currentStatus) async {
    if (id == null) return;
    final newStatus = currentStatus == "activity" ? "inactive" : "activity";
    final result = await ApiService.toggleUserStatus(id, newStatus);
    if (result) {
      showSnackbar(
          "Đã cập nhật trạng thái: ${newStatus == 'activity' ? 'Hoạt động' : 'Đã khóa'}");
      fetchUsers();
    } else {
      showSnackbar("Lỗi cập nhật trạng thái", isError: true);
    }
  }

  Future<void> _changeUserRole(String id, String newRole) async {
    final result = await ApiService.changeUserRole(id, newRole);
    if (result) {
      showSnackbar("Đã phân quyền thành công: ${newRole.toUpperCase()}");
      fetchUsers();
    } else {
      showSnackbar("Lỗi phân quyền", isError: true);
    }
  }

  void _createUser() {
    context.push('/admin/create_account');
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quản Lý Người Dùng",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Phân quyền & Bảo mật Blockchain",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(onPressed: fetchUsers, icon: Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM & THỐNG KÊ
          _buildTopBar(),

          // 2. DANH SÁCH NGƯỜI DÙNG
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(filteredUsers[index]);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add_alt_1),
        label: Text("Tạo Tài Khoản"),
      ),
    );
  }

  // --- WIDGET CON: THANH TÌM KIẾM ---
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              SizedBox(height: 10),
              TextField(
                controller: searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: "Tìm theo tên, email...",
                  prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatBadge("Tổng: ${users.length}", Colors.white24),
                  _buildStatBadge(
                      "Admin: ${users.where((u) => u['role'] == 'admin').length}",
                      kAdminColor),
                  _buildStatBadge(
                      "Active: ${users.where((u) => u['status'] == 'activity').length}",
                      kActiveColor),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // --- WIDGET CON: USER CARD ---
  Widget _buildUserCard(dynamic user) {
    String role = user['role'] ?? 'guest';
    String status = user['status'] ?? 'unknown';
    bool isActive = status == 'activity';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _getRoleColor(role).withOpacity(0.1),
              child: Icon(_getRoleIcon(role),
                  color: _getRoleColor(role), size: 28),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: isActive ? kActiveColor : kInactiveColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
              ),
            )
          ],
        ),
        title: Text(user['name'] ?? 'Chưa đặt tên',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            SizedBox(height: 8),
            Row(
              children: [
                _buildRoleChip(role),
                SizedBox(width: 8),
                if (!isActive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: kInactiveColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text("Đã khóa",
                        style: TextStyle(
                            fontSize: 10,
                            color: kInactiveColor,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            )
          ],
        ),
        trailing: _buildActionMenu(user),
      ),
    );
  }

  // --- WIDGET CON: ACTION MENU (3 CHẤM) ---
  Widget _buildActionMenu(dynamic user) {
    bool isActive = user['status'] == 'activity';
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'toggle') {
          _toggleUserActive(user['_id'], user['status']);
        } else if (value == 'role') {
          _showRoleSelectionMenu(user['_id'], user['role']);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'role',
          child: Row(children: [
            Icon(Icons.security, color: Colors.blue, size: 20),
            SizedBox(width: 10),
            Text("Phân quyền")
          ]),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(children: [
            Icon(isActive ? Icons.block : Icons.check_circle,
                color: isActive ? kInactiveColor : kActiveColor, size: 20),
            SizedBox(width: 10),
            Text(isActive ? "Khóa tài khoản" : "Kích hoạt lại")
          ]),
        ),
      ],
    );
  }

  // --- HELPER: CHIPS & ICONS ---
  Widget _buildRoleChip(String role) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: _getRoleColor(role).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _getRoleColor(role).withOpacity(0.3))),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _getRoleColor(role)),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return kAdminColor;
      case 'doctor':
        return kDoctorColor;
      case 'staff':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.verified_user; // Khiên bảo mật
      case 'doctor':
        return Icons.medical_services; // Y tế
      case 'staff':
        return Icons.badge; // Thẻ nhân viên
      default:
        return Icons.person;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          SizedBox(height: 10),
          Text("Không tìm thấy người dùng",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET: CHỌN QUYỀN ---
  void _showRoleSelectionMenu(String userId, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cấp quyền truy cập (Blockchain Roles)",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor)),
            SizedBox(height: 10),
            _buildRoleOption(userId, 'admin', "Quản trị viên (Toàn quyền)"),
            _buildRoleOption(userId, 'doctor', "Bác sĩ (Xem/Sửa bệnh án)"),
            _buildRoleOption(userId, 'staff', "Nhân viên (Quản lý lịch hẹn)"),
            _buildRoleOption(
                userId, 'patient', "Bệnh nhân (Xem hồ sơ cá nhân)"),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String userId, String role, String desc) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: _getRoleColor(role).withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
      ),
      title: Text(role.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        _changeUserRole(userId, role);
      },
    );
  }
}
