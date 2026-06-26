import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';

// --- PALETTE MÀU ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kActiveColor = Color(0xFF4CAF50);
const Color kInactiveColor = Color(0xFFE57373);
const Color kAdminColor = Color(0xFF673AB7);
const Color kDoctorColor = Color(0xFF00ACC1);

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  // --- CONTROLLERS CHO FORM TẠO TÀI KHOẢN ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'patient';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC API ---
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() {
        users = data;
        filteredUsers = data;
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

  // 1. TÍCH HỢP LOGIC KHÓA TÀI KHOẢN TỪ ACCOUNT MANAGER
  Future<void> _toggleUserActive(String id) async {
    if (id.isEmpty) return;

    // Sử dụng hàm toggleAdminUserStatus lấy từ AccountManagerScreen
    final result = await ApiService.toggleAdminUserStatus(id);

    if (result['success'] == true) {
      showSnackbar(result['message'] ?? "Đã cập nhật trạng thái thành công");
      fetchUsers();
    } else {
      showSnackbar("Lỗi: ${result['message']}", isError: true);
    }
  }

  // 2. TÍCH HỢP LOGIC TẠO TÀI KHOẢN TỪ ACCOUNT MANAGER
  Future<void> _createBaseAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showSnackbar("Vui lòng điền đủ thông tin: Tên, Email, Mật khẩu",
          isError: true);
      return;
    }

    final result = await ApiService.createBaseAccount(
        name, email, password, _selectedRole);

    if (result['success'] == true) {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      fetchUsers();
      if (mounted) {
        Navigator.pop(context); // Đóng Dialog
        showSnackbar(result['message'] ?? "Tạo tài khoản thành công");
      }
    } else {
      showSnackbar("Lỗi: ${result['message']}", isError: true);
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

  // 3. DIALOG TẠO TÀI KHOẢN (THAY THẾ CHUYỂN TRANG)
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1,
                  size: 50, color: kPrimaryColor),
              const SizedBox(height: 16),
              const Text(
                'Tạo Tài Khoản Mới',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm nhân sự mới vào hệ thống',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Họ và tên', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', Icons.email,
                  isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Mật khẩu', Icons.lock,
                  isPassword: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Vai trò (Role)',
                  prefixIcon: const Icon(Icons.security, color: kPrimaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
                items: [
                  'admin',
                  'doctor',
                  'patient',
                  'receptionist',
                  'cashier',
                  'pharmacy'
                ]
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createBaseAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tạo Mới',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
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
        onPressed: _showAddDialog, // Gọi Dialog thay vì chuyển trang
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Tạo Tài Khoản",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      // 1. Thêm căn chỉnh lên top thay vì dùng widget Center
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          // 2. Ép Column co lại vừa đúng với nội dung bên trong nó
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                height:
                    10), // Lưu ý: Nếu có SafeArea, bạn có thể cân nhắc bỏ khoảng trống này
            TextField(
              controller: searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: "Tìm theo tên, email...",
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 10),
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
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // --- WIDGET CON: USER CARD CHUYÊN NGHIỆP HƠN ---
  Widget _buildUserCard(dynamic user) {
    String role = user['role'] ?? 'guest';
    String status = user['status'] ?? 'unknown';
    bool isActive = status == 'activity';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: isActive ? Colors.transparent : Colors.red.withOpacity(0.3),
            width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isActive
                  ? _getRoleColor(role).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(_getRoleIcon(role),
                  color: isActive ? _getRoleColor(role) : Colors.red, size: 28),
            ),
            if (!isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.lock, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          user['name'] ?? 'Chưa đặt tên',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isActive ? Colors.black87 : Colors.red.shade900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Icon(Icons.email, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(user['email'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        // HIỂN THỊ NÚT TRỰC QUAN THAY VÌ GIẤU TRONG 3 CHẤM
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showRoleSelectionMenu(user['_id'], role),
              child: _buildRoleChip(role),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: isActive ? 'Khóa tài khoản' : 'Mở khóa',
              icon: Icon(
                isActive ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: isActive ? Colors.green : Colors.red,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    (isActive ? Colors.green : Colors.red).withOpacity(0.1),
              ),
              onPressed: () => _toggleUserActive(user['_id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(role)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 12, color: _getRoleColor(role)),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return kAdminColor;
      case 'doctor':
        return kDoctorColor;
      case 'receptionist':
        return Colors.teal;
      case 'cashier':
        return Colors.orange;
      case 'pharmacy':
        return Colors.purple;
      case 'patient':
        return Colors.cyan;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'doctor':
        return Icons.medical_services;
      case 'receptionist':
        return Icons.support_agent;
      case 'cashier':
        return Icons.point_of_sale;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'patient':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("Không tìm thấy người dùng",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET: CHỌN QUYỀN ---
  void _showRoleSelectionMenu(String userId, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cấp quyền truy cập (Blockchain Roles)",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor),
            ),
            const SizedBox(height: 10),
            _buildRoleOption(userId, 'admin', "Quản trị viên (Toàn quyền)"),
            _buildRoleOption(userId, 'doctor', "Bác sĩ (Xem/Sửa bệnh án)"),
            _buildRoleOption(userId, 'receptionist', "Lễ tân"),
            _buildRoleOption(userId, 'cashier', "Thu ngân"),
            _buildRoleOption(userId, 'pharmacy', "Quản lý dược phẩm, vật tư"),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: _getRoleColor(role).withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
      ),
      title: Text(role.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        _changeUserRole(userId, role);
      },
    );
  }
}
