import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_application_datlichkham/screens/screens_admin/security_screens/security_ayth.dart'; (Nếu cần redirect)

class CreateUserScreenState extends StatefulWidget {
  @override
  _CreateUserScreenStateState createState() => _CreateUserScreenStateState();
}

class _CreateUserScreenStateState extends State<CreateUserScreenState> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  String name = '', email = '', password = '', confirmPassword = '';
  String selectedRole = 'staff'; // Role mặc định
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  void showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Nền xám nhạt hiện đại
      appBar: AppBar(
        title: Text("Tạo Tài Khoản Mới",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. LOGO BO TRÒN & SLOGAN
              _buildHeader(),

              SizedBox(height: 0),

              // 2. FORM NHẬP LIỆU (CARD)
              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Thông tin tài khoản",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),

                        _buildTextField("Họ và tên", Icons.person, false,
                            (value) => name = value),
                        SizedBox(height: 10),

                        _buildTextField("Email", Icons.email, false,
                            (value) => email = value),
                        SizedBox(height: 10),

                        _buildPasswordField(
                            "Mật khẩu",
                            isPasswordVisible,
                            (value) => password = value,
                            () => setState(
                                () => isPasswordVisible = !isPasswordVisible)),
                        SizedBox(height: 10),

                        _buildPasswordField(
                            "Xác nhận mật khẩu",
                            isConfirmPasswordVisible,
                            (value) => confirmPassword = value,
                            () => setState(() => isConfirmPasswordVisible =
                                !isConfirmPasswordVisible)),
                        SizedBox(height: 10),

                        // 3. DROPDOWN ROLE (TÙY CHỈNH ĐẸP)
                        _buildRoleDropdown(),
                        SizedBox(height: 10),

                        // 4. NÚT ĐĂNG KÝ
                        ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          child: Text("Tạo Tài Khoản",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (password != confirmPassword) {
        showSnackbar("Mật khẩu không khớp", isError: true);
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = await prefs.getString('token'); // ✅ LẤY TOKEN
        if (token == null) {
          showSnackbar("Bạn chưa đăng nhập", isError: true);
          return;
        }
        final error = await ApiService.registerUserByAdmin(
          name,
          email,
          password,
          confirmPassword,
          selectedRole,
          token, // ✅ THÊM TOKEN VÀO ĐÂY
        );

        if (!mounted) return;

        if (error == null) {
          showSnackbar("Tạo tài khoản thành công!");
          context.pop();
        } else {
          showSnackbar(error, isError: true);
        }
      } catch (e) {
        logger.e("Lỗi exception: $e");
        showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
      }
    }
  }

  // --- WIDGET CON: HEADER ---
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4), // Viền trắng
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png', // Đảm bảo ảnh tồn tại
              height: 100, width: 100, fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 15),
        Text(
          "Smart Clinic",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.blue.shade900),
        ),
        Text(
          "Quản trị hệ thống & Phân quyền",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // --- WIDGET CON: TEXT FIELD ---
  Widget _buildTextField(String label, IconData icon, bool isPassword,
      Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: isPassword,
      validator: (value) => value!.isEmpty ? "Vui lòng nhập $label" : null,
      onChanged: onChanged,
    );
  }

  // --- WIDGET CON: PASSWORD FIELD ---
  Widget _buildPasswordField(String label, bool isVisible,
      Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: !isVisible,
      validator: (value) =>
          value!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
      onChanged: onChanged,
    );
  }

  // --- WIDGET CON: ROLE DROPDOWN ---
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      items: [
        {'val': 'admin', 'label': 'Quản Trị Viên', 'icon': Icons.security},
        {'val': 'doctor', 'label': 'Bác Sĩ', 'icon': Icons.medical_services},
        {'val': 'staff', 'label': 'Nhân Viên', 'icon': Icons.badge},
      ].map((item) {
        return DropdownMenuItem(
          value: item['val'] as String,
          child: Row(
            children: [
              Icon(item['icon'] as IconData, size: 20, color: Colors.blueGrey),
              SizedBox(width: 10),
              Text(item['label'] as String),
            ],
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: "Vai trò hệ thống",
        prefixIcon: Icon(Icons.vpn_key, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) => setState(() => selectedRole = value!),
    );
  }
}
