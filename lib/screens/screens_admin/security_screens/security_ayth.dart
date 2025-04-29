import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'create_account_screen.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await ApiService.getUsers();
      print('Dữ liệu người dùng: $data'); // Log dữ liệu để kiểm tra
      setState(() {
        users = data;
      });
    } catch (e) {
      print("Lỗi khi lấy người dùng: $e");
      showSnackbar("Lỗi khi tải dữ liệu: $e", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return; // Sử dụng mounted thay vì context.mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _toggleUserActive(String userId, String currentStatus) async {
    if (userId == null) {
      showSnackbar("Không tìm thấy ID người dùng", isError: true);
      return;
    }
    final newStatus = currentStatus == "activity" ? "inactive" : "activity";
    final result = await ApiService.toggleUserStatus(userId, newStatus);
    if (result == "success") {
      showSnackbar("Cập nhật trạng thái thành công");
      fetchUsers();
    } else {
      showSnackbar("Lỗi khi cập nhật trạng thái: $result", isError: true);
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    if (userId == null) {
      showSnackbar("Không tìm thấy ID người dùng", isError: true);
      return;
    }
    final result = await ApiService.changeUserRole(userId, newRole);
    if (result == "success") {
      showSnackbar("Cập nhật vai trò thành công");
      fetchUsers();
    } else {
      showSnackbar("Lỗi khi cập nhật vai trò: $result", isError: true);
    }
  }

  void _createUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateUserScreenState()),
    ).then((_) {
      fetchUsers();
    });
  }

  void _showRoleSelectionMenu(String userId, String currentRole) {
    if (!mounted) return; // Kiểm tra widget còn tồn tại
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép bottom sheet cuộn
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Chọn vai trò mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(),
                _buildRoleOption(sheetContext, userId, 'patient'),
                _buildRoleOption(sheetContext, userId, 'staff'),
                _buildRoleOption(sheetContext, userId, 'doctor'),
                _buildRoleOption(sheetContext, userId, 'admin'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(BuildContext sheetContext, String userId, String role) {
    return ListTile(
      leading: Icon(Icons.person, color: Colors.blue),
      title: Text(
        role.toUpperCase(),
        style: TextStyle(fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(sheetContext); // Đóng bottom sheet
        _confirmChangeRole(userId, role);
      },
    );
  }

  void _confirmChangeRole(String userId, String newRole) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Xác nhận đổi vai trò'),
          content: Text('Bạn có chắc muốn đổi vai trò thành "$newRole"?'),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            TextButton(
              child: Text('Xác nhận'),
              onPressed: () async {
                Navigator.pop(dialogContext); // Đóng dialog
                await _changeUserRole(userId, newRole);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Phân quyền & Bảo mật"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('Không có dữ liệu'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          user['role'] == 'doctor'
                              ? Icons.medical_services
                              : Icons.admin_panel_settings,
                          size: 40,
                        ),
                        title: Text(user['name'] ?? 'Không có tên'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'Không có email'),
                            Text("Role: ${user['role'] ?? 'Không xác định'}"),
                            Text(
                              "Status: ${user['status'] == 'activity' ? 'Hoạt động' : 'Vô hiệu hóa'}",
                              style: TextStyle(
                                color: user['status'] == 'activity' ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            print('Lựa chọn: $value'); // Log lựa chọn
                            if (value == 'toggle') {
                              _toggleUserActive(user['_id'], user['status']);
                            } else if (value == 'change_role') {
                              _showRoleSelectionMenu(user['_id'], user['role'] ?? 'patient');
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'change_role',
                              child: Text('Chuyển vai trò'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(user['status'] == 'activity'
                                  ? 'Vô hiệu hóa'
                                  : 'Kích hoạt lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: Icon(Icons.person_add),
        tooltip: 'Thêm người dùng',
      ),
    );
  }
}