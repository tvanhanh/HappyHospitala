import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/security_screens/security_ayth.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:logger/logger.dart';

class CreateUserScreenState extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  String name = '', email = '', password = '', confirmPassword = '';
  String selectedRole = 'staff'; // ✅ Role mặc định
  bool isPasswordVisible = false, isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    void showSnackbar(String msg, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: isError ? Colors.red : Colors.green),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/logo.png', height: 80),
                      SizedBox(height: 10),
                      Text(
                        "Chăm sóc sức khỏe toàn diện - Vì bạn xứng đáng!",
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Đăng ký tài khoản",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Nhập thông tin của bạn để tạo tài khoản",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 25),

                      _buildTextField("Họ và tên", Icons.person, false, (value) => name = value),
                      SizedBox(height: 15),
                      _buildTextField("Email", Icons.email, false, (value) => email = value),
                      SizedBox(height: 15),
                      _buildPasswordField("Mật khẩu", isPasswordVisible, (value) => password = value, () {}),
                      SizedBox(height: 15),

                      // ✅ Dropdown chọn Role
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: ['admin', 'doctor', 'staff']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role == 'admin'
                                        ? 'Quản trị viên'
                                        : role == 'doctor'
                                            ? 'Bác sĩ'
                                            : 'Nhân viên',
                                  ),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: "Quyền tài khoản",
                          prefixIcon: Icon(Icons.security, color: Colors.blue.shade700),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            selectedRole = value;
                          }
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? "Vui lòng chọn quyền" : null,
                      ),
                      SizedBox(height: 15),

                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (password != confirmPassword) {
                              if (!context.mounted) return;
                              showSnackbar("Mật khẩu không khớp", isError: true);
                              return;
                            }
                            try {
                              final error = await ApiService.registerUser(
                                name,
                                email,
                                password,
                                confirmPassword,
                               // selectedRole, // ✅ Truyền role
                              );

                              if (!context.mounted) return;
                              if (error == null) {
                                showSnackbar("Đăng ký thành công");
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserManagementScreen(),
                                  ),
                                );
                              } else {
                                showSnackbar(error, isError: true);
                              }
                            } catch (e) {
                              logger.e("Lỗi exception: $e");
                              showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 80),
                        ),
                        child: Text("Đăng ký", style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, bool isPassword, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      obscureText: isPassword,
      validator: (value) => value!.isEmpty ? "Không được để trống" : null,
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField(String label, bool isVisible, Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: !isVisible,
      validator: (value) =>
          value!.length < 6 ? "Mật khẩu ít nhất 6 ký tự" : null,
      onChanged: onChanged,
    );
  }
}
