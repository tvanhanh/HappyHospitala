import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'change_password_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screen_doctor/home.dart';
import 'screen_staff/home.dart';
import 'screens_admin/home.dart';
import '../services/config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 400, // ✅ Giới hạn chiều rộng tối đa
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Logo bệnh viện
                      Image.asset('assets/logo.png', height: 80),
                      SizedBox(height: 10),

                      // ✅ Câu slogan tạo uy tín
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
                        "Chào mừng trở lại!",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Đăng nhập để tiếp tục",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 25),

                      // ✅ Input Email
                      _buildTextField("Email", Icons.email, false,
                          (value) => email = value),
                      SizedBox(height: 15),

                      // ✅ Input Mật khẩu
                      _buildTextField("Mật khẩu", Icons.lock, true,
                          (value) => password = value),
                      SizedBox(height: 20),

                      // ✅ Nút Đăng nhập
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            
                             final result = await ApiService.loginUser(email, password);
                            if (!context.mounted) return;
                            

                            if (result != null && result['error'] == null) {
                               final role = result['role'];
                              

                           if (role == 'admin') {
                           Navigator.pushReplacement(
                           context,
                           MaterialPageRoute(builder: (_) => AdminDashboard()),
                            );
                           } else if (role == 'patient') {
                           Navigator.pushReplacement(
                            context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                            );
                          } else {
        // Role không xác định → về trang chủ hoặc báo lỗi
                           Navigator.pushReplacement(
                            context,
                           MaterialPageRoute(builder: (_) => HomeScreen()),
                           );
                         }
                      } else {
      
                         ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(result?['error'] ?? 'Đăng nhập thất bại')),
                          );
                         }
                        }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 100),
                        ),
                        child:
                            Text("Đăng nhập", style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 15),

                      // ✅ Quên mật khẩu & Đổi mật khẩu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordScreen()));
                            },
                            child: Text("Quên mật khẩu?",
                                style: TextStyle(color: Colors.blue.shade700)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ChangePasswordScreen()));
                            },
                            child: Text("Đổi mật khẩu",
                                style: TextStyle(color: Colors.blue.shade700)),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      // ✅ Dòng phân cách
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Hoặc",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                        ],
                      ),

                      SizedBox(height: 15),

                      // ✅ Đăng nhập bằng Google
                      _buildSocialButton("Đăng nhập với Google",
                          Icons.g_mobiledata_outlined, Colors.red.shade600),
                      SizedBox(height: 10),

                      // ✅ Đăng nhập bằng Facebook
                      _buildSocialButton("Đăng nhập với Facebook",
                          Icons.facebook, Colors.blue.shade900),

                      SizedBox(height: 20),

                      // ✅ Chưa có tài khoản? Đăng ký ngay
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Chưa có tài khoản?",
                              style: TextStyle(color: Colors.grey.shade700)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RegisterScreen()));
                            },
                            child: Text("Đăng ký ngay",
                                style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
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

  /// ✅ Widget tạo TextField
  Widget _buildTextField(String label, IconData icon, bool isPassword,
      Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey),
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

  /// ✅ Widget tạo nút đăng nhập Google & Facebook
  Widget _buildSocialButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 24),
      label: Text(label, style: TextStyle(fontSize: 16)),
    );
  }
}
