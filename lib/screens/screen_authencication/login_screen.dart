import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/home_screen.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
//import '../screen_patient/home_screen.dart';
import 'change_password_screen.dart';

import '../screen_doctor/doctor_home_screen.dart';
import '../screens_admin/admin_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
                            (value) => email = value!, controller: _emailController),
                        SizedBox(height: 15), // ✅ Giảm khoảng cách
                        _buildTextField("Mật khẩu", Icons.lock, true,
                            (value) => password = value!, controller: _passwordController),
                        SizedBox(height: 10), // ✅ Giữ khoảng cách vừa phải

                        // --- NÚT ĐĂNG NHẬP CHÍNH ---
                        SizedBox(
                          width: double.infinity,
                          height: 45, // ✅ Giảm chiều cao nút
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate() || kDebugMode) {
                                final loginEmail = kDebugMode && _emailController.text.isNotEmpty ? _emailController.text : email;
                                final loginPass = kDebugMode && _passwordController.text.isNotEmpty ? _passwordController.text : password;
                                final errorMsg = await ref.read(authProvider.notifier).login(loginEmail, loginPass);
                                if (!context.mounted) return;
                                // [Logic chuyển hướng]
                                if (errorMsg == null) {
                                  final role = ref.read(authProvider).role.value;

                                  if (role == 'admin') {
                                    context.go('/admin');
                                  } else if (role == 'patient') {
                                    context.go('/home');
                                  } else if (role == 'doctor') {
                                    context.go('/doctor');
                                  } else if (role == 'receptionist') {
                                    context.go('/receptionist/dashboard');
                                  } else if (role == 'cashier') {
                                    context.go('/cashier');
                                  } else if (role == 'pharmacy') {
                                    context.go('/pharmacy');
                                  } else {
                                    context.go('/home'); // Fallback
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(errorMsg ??
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

                        if (kDebugMode) _buildDevQuickLogin(),

                        // --- QUÊN MẬT KHẨU & ĐỔI MẬT KHẨU ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.go('/auth/change_password_page');
                              },
                              child: Text("Quên mật khẩu?",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/auth/change_password_reset');
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
                                context.go('/auth/register');
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

  Widget _buildDevQuickLogin() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Column(
        children: [
          Text("🛠️ DEV QUICK LOGIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _devLoginBtn("Admin", "admin@gmail.com"),
              _devLoginBtn("Bác Sĩ", "phino18@gmail.com"),
              _devLoginBtn("Bệnh Nhân", "patient1@gmail.com"),
              _devLoginBtn("Lễ Tân", "receptionist@gmail.com"),
              _devLoginBtn("Thu Ngân", "cashier@gmail.com"),
              _devLoginBtn("Dược Sĩ", "pharmacist@gmail.com"),
            ],
          )
        ],
      ),
    );
  }

  Widget _devLoginBtn(String title, String devEmail) {
    return ActionChip(
      label: Text(title, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.amber.shade300,
      onPressed: () {
        _emailController.text = devEmail;
        _passwordController.text = "123456";
        email = devEmail;
        password = "123456";
        // Trigger login
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
        // Gọi thẳng loginUser logic để nó tự đăng nhập
        ref.read(authProvider.notifier).login(email, password).then((errorMsg) {
          if (!mounted) return;
          if (errorMsg == null) {
            final role = ref.read(authProvider).role.value;
            if (role == 'admin') context.go('/admin');
            else if (role == 'patient') context.go('/home');
            else if (role == 'doctor') context.go('/doctor');
            else if (role == 'receptionist') context.go('/receptionist/dashboard');
            else if (role == 'cashier') context.go('/cashier');
            else if (role == 'pharmacy') context.go('/pharmacy');
            else context.go('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        });
      },
    );
  }

  /// ✅ Widget tạo TextField
  Widget _buildTextField(String label, IconData icon, bool isPassword,
      Function(String) onChanged, {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
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
