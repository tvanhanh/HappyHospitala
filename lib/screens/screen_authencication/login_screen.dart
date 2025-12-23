import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/home_screen.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
//import '../screen_patient/home_screen.dart';
import 'change_password_screen.dart';

import '../screen_doctor/doctor_home_screen.dart';
import '../screen_staff/home.dart';
import '../screens_admin/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isPasswordVisible = false;

  final String googleLogoPath = 'assets/google_logo.png';
  final String facebookLogoPath = 'assets/facebook_logo.png';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Giảm Max width một chút để đảm bảo an toàn trên các thiết bị nhỏ hơn
    final cardWidth = screenWidth > 400 ? 400.0 : screenWidth * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // ✅ Giảm padding dọc tổng thể
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
            child: SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  // ✅ Giảm padding bên trong Card
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- LOGO VÀ SLOGAN ---
                        ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 90, // ✅ Giảm kích thước logo
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 10), // ✅ Giảm khoảng cách
                        Text(
                          "Chăm sóc sức khỏe toàn diện - Vì bạn xứng đáng!",
                          style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.lightBlue.shade700,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10), // ✅ Giảm khoảng cách

                        // --- TIÊU ĐỀ ---
                        Text(
                          "Chào mừng trở lại!",
                          style: TextStyle(
                              fontSize: 24, // ✅ Giảm font size
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade900),
                        ),
                        Text(
                          "Đăng nhập để tiếp tục",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 10), // ✅ Giữ khoảng cách vừa phải

                        // --- INPUT FIELDS ---
                        _buildTextField("Email", Icons.email, false,
                            (value) => email = value!),
                        SizedBox(height: 15), // ✅ Giảm khoảng cách
                        _buildTextField("Mật khẩu", Icons.lock, true,
                            (value) => password = value!),
                        SizedBox(height: 10), // ✅ Giữ khoảng cách vừa phải

                        // --- NÚT ĐĂNG NHẬP CHÍNH ---
                        SizedBox(
                          width: double.infinity,
                          height: 45, // ✅ Giảm chiều cao nút
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final result =
                                    await ApiService.loginUser(email, password);
                                if (!context.mounted) return;
                                // [Logic chuyển hướng]
                                if (result != null && result['error'] == null) {
                                  final role = result['role'];
                                  if (role == 'admin') {
                                    context.go('/admin');
                                  } else if (role == 'patient') {
                                    context.go('/home');
                                  } else if (role == 'doctor') {
                                    context.go('/doctor');
                                  } else if (role == 'staff') {
                                    context.go('/staff');
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result?['error'] ??
                                            'Đăng nhập thất bại')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                            ),
                            child: Text("Đăng nhập",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: 15), // ✅ Giảm khoảng cách

                        // --- QUÊN MẬT KHẨU & ĐỔI MẬT KHẨU ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.go('/change-password-page');
                              },
                              child: Text("Quên mật khẩu?",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/change-password-reset');
                              },
                              child: Text("Đổi mật khẩu",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        SizedBox(height: 15), // ✅ Giảm khoảng cách

                        // --- DÒNG PHÂN CÁCH HOẶC ---
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade400)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8), // ✅ Giảm padding
                              child: Text("Hoặc",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)), // ✅ Giảm font size
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),
                        SizedBox(height: 10), // ✅ Giảm khoảng cách

                        // --- NÚT ĐĂNG NHẬP MẠNG XÃ HỘI ---
                        _buildSocialButton(
                            "Đăng nhập với Google", googleLogoPath),
                        SizedBox(height: 10), // ✅ Giảm khoảng cách

                        _buildSocialButton(
                            "Đăng nhập với Facebook", facebookLogoPath),
                        SizedBox(height: 10), // ✅ Giảm khoảng cách

                        // --- CHƯA CÓ TÀI KHOẢN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Chưa có tài khoản?",
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 14)),
                            TextButton(
                              onPressed: () {
                                context.go('/register');
                              },
                              child: Text("Đăng ký ngay",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ],
                        ),

                        // ✅ KHOẢNG ĐỆM PHỤ QUAN TRỌNG NHẤT (Giảm nhưng vẫn giữ)
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HÀM HỖ TRỢ DYNAMICALLY BUILT ---

  /// ✅ Widget tạo TextField
  Widget _buildTextField(String label, IconData icon, bool isPassword,
      Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)), // ✅ Bo góc nhỏ hơn
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                    size: 20), // ✅ Giảm kích thước icon
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : null,
      ),
      obscureText: isPassword ? !isPasswordVisible : false,
      validator: (value) => value!.isEmpty ? "Không được để trống" : null,
      onChanged: onChanged,
    );
  }

  /// ✅ Widget tạo nút đăng nhập Google & Facebook (Đã tối ưu)
  Widget _buildSocialButton(String text, String logoPath) {
    return SizedBox(
      width: double.infinity,
      height: 45, // ✅ Giảm chiều cao nút
      child: ElevatedButton(
        onPressed: () {
          print('$text clicked');
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ✅ Giảm bo góc
            side: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(logoPath, height: 20), // ✅ Giảm kích thước logo
            SizedBox(width: 15), // ✅ Giảm khoảng cách
            // Chữ của nút
            Text(
              text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
