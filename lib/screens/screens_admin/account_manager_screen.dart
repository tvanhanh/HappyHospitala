import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/admin_stats_provider.dart';
import '../../services/api_service.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kSecondary = Color(0xFF0D47A1);

class AccountManagerScreen extends ConsumerStatefulWidget {
  const AccountManagerScreen({super.key});

  @override
  ConsumerState<AccountManagerScreen> createState() => _AccountManagerScreenState();
}

class _AccountManagerScreenState extends ConsumerState<AccountManagerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'doctor';

  Future<void> _createBaseAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin: Tên, Email, Mật khẩu')),
      );
      return;
    }

    final result = await ApiService.createBaseAccount(name, email, password, _role);

    if (result['success']) {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      ref.invalidate(usersProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String id) async {
    final result = await ApiService.toggleAdminUserStatus(id);

    if (result['success']) {
      ref.invalidate(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
              const Icon(Icons.person_add_alt_1, size: 50, color: _kPrimary),
              const SizedBox(height: 16),
              const Text(
                'Tạo Tài Khoản Mới',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm nhân sự mới vào hệ thống',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Họ và tên', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', Icons.email, isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Mật khẩu', Icons.lock, isPassword: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Vai trò (Role)',
                  prefixIcon: const Icon(Icons.security, color: _kPrimary),
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
                ),
                items: ['admin', 'doctor', 'patient', 'receptionist', 'cashier', 'pharmacy']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createBaseAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tạo Mới', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimary),
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
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: asyncUsers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Chưa có người dùng nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isLocked = user.status == 'inactive';
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isLocked ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isLocked ? Colors.red.withValues(alpha: 0.1) : _kPrimary.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: isLocked ? Colors.red : _kPrimary, size: 28),
                      ),
                      if (isLocked)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.lock, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    user.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: isLocked ? Colors.red.shade900 : const Color(0xFF1A1A2E),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getRoleColor(user.role).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: isLocked ? 'Mở khóa' : 'Khóa tài khoản',
                        icon: Icon(
                          isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: isLocked ? Colors.green : Colors.red,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: (isLocked ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        ),
                        onPressed: () => _toggleUserStatus(user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        elevation: 4,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm Tài Khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'doctor': return Colors.blue;
      case 'patient': return Colors.green;
      case 'receptionist': return Colors.purple;
      case 'cashier': return Colors.orange;
      case 'pharmacy': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
