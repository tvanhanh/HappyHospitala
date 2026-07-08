import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/home_screen.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
// import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import '../../models/app_role.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'change_password_page.dart';

import '../screen_doctor/doctor_home_screen.dart';
import '../screens_admin/admin_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? password;

  const LoginScreen({super.key, this.email, this.password});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String email = "";
  String password = "";
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
      email = widget.email!;
    }
    if (widget.password != null) {
      _passwordController.text = widget.password!;
      password = widget.password!;
    }

    // Lắng nghe sự kiện đăng nhập của Google Sign In (cho cả web và các nền tảng khác)
    _authSubscription =
        GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final GoogleSignInAccount googleUser = event.user;
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final idToken = googleAuth.idToken;

        if (idToken != null) {
          final errorMsg =
              await ref.read(authProvider.notifier).loginWithGoogle(idToken);
          if (!mounted) return;
          if (errorMsg == null) {
            final role = ref.read(authProvider).role.value;
            if (role == 'admin')
              context.go('/admin');
            else if (role == 'patient')
              context.go('/home');
            else if (role == 'doctor')
              context.go('/doctor');
            else if (role == 'receptionist')
              context.go('/receptionist/dashboard');
            else if (role == 'cashier')
              context.go('/cashier/dashboard');
            else if (role == 'pharmacy')
              context.go('/pharmacy/dashboard');
            else
              context.go('/home');
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      if (kIsWeb) {
        // Trên Web, luồng đăng nhập được điều khiển hoàn toàn bởi renderButton và stream ở initState
        return;
      }
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken != null) {
        final errorMsg =
            await ref.read(authProvider.notifier).loginWithGoogle(idToken);
        if (!mounted) return;
        if (errorMsg == null) {
          final role = ref.read(authProvider).role.value;
          if (role == 'admin')
            context.go('/admin');
          else if (role == 'patient')
            context.go('/home');
          else if (role == 'doctor')
            context.go('/doctor');
          else if (role == 'receptionist')
            context.go('/receptionist/dashboard');
          else if (role == 'cashier')
            context.go('/cashier/dashboard');
          else if (role == 'pharmacy')
            context.go('/pharmacy/dashboard');
          else
            context.go('/home');
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (error) {
      print("Google sign in error: $error");
      if (error.toString().contains("canceled") ||
          error.toString().contains("cancelled")) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi đăng nhập Google.")));
    }
  }

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
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
                            height: 60, // ✅ Thu nhỏ logo
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8), // ✅ Giảm khoảng cách

                        // --- TIÊU ĐỀ ---
                        Text(
                          "Chào mừng trở lại!",
                          style: TextStyle(
                              fontSize: 22, // ✅ Giảm font size
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade900),
                        ),
                        Text(
                          "Đăng nhập để tiếp tục",
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 16), // ✅ Giữ khoảng cách vừa phải

                        // --- INPUT FIELDS ---
                        _buildTextField("Email hoặc Số điện thoại", Icons.email,
                            false, (value) => email = value!,
                            controller: _emailController),
                        SizedBox(height: 12), // ✅ Giảm khoảng cách
                        _buildTextField("Mật khẩu", Icons.lock, true,
                            (value) => password = value!,
                            controller: _passwordController),
                        SizedBox(height: 20), // ✅ Giữ khoảng cách vừa phải

                        // --- NÚT ĐĂNG NHẬP CHÍNH ---
                        SizedBox(
                          width: double.infinity,
                          height: 45, // ✅ Giảm chiều cao nút
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate() ||
                                  kDebugMode) {
                                final loginEmail = kDebugMode &&
                                        _emailController.text.isNotEmpty
                                    ? _emailController.text
                                    : email;
                                final loginPass = kDebugMode &&
                                        _passwordController.text.isNotEmpty
                                    ? _passwordController.text
                                    : password;
                                final errorMsg = await ref
                                    .read(authProvider.notifier)
                                    .login(loginEmail, loginPass);
                                if (!context.mounted) return;
                                // [Logic chuyển hướng]
                                if (errorMsg == null) {
                                  final role =
                                      ref.read(authProvider).role.value;

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
                                  } else if (role == 'pharmacy_manager') {
                                    context.go('/pharmacy');
                                  } else {
                                    context.go('/home'); // Fallback
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            errorMsg ?? 'Đăng nhập thất bại')),
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

                        // --- QUÊN MẬT KHẨU ---
                        TextButton(
                          onPressed: () {
                            context.go('/auth/forgot_password');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text("Quên mật khẩu?",
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                        SizedBox(height: 12), // ✅ Giảm khoảng cách

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
                        SizedBox(height: 12), // ✅ Giảm khoảng cách

                        // --- NÚT ĐĂNG NHẬP MẠNG XÃ HỘI ---
                        // kIsWeb
                        //     ? SizedBox(
                        //         width: double.infinity,
                        //         height: 40, // Match design height
                        //         child: (GoogleSignInPlatform.instance
                        //                 as web.GoogleSignInPlugin)
                        //             .renderButton(),
                        //       )
                        //     : _buildSocialButton("Đăng nhập với Google",
                        //         googleLogoPath, _handleGoogleSignIn),
                        SizedBox(height: 16), // ✅ Giảm khoảng cách

                        // --- CHƯA CÓ TÀI KHOẢN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Chưa có tài khoản?",
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 13)),
                            TextButton(
                              onPressed: () {
                                context.go('/auth/register');
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text("Đăng ký ngay",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
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
          Text("🛠️ DEV QUICK LOGIN",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
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
            if (role == 'admin')
              context.go('/admin');
            else if (role == 'patient')
              context.go('/home');
            else if (role == 'doctor')
              context.go('/doctor');
            else if (role == 'receptionist')
              context.go('/receptionist/dashboard');
            else if (role == 'cashier')
              context.go('/cashier/dashboard');
            else if (role == 'pharmacy')
              context.go('/pharmacy/dashboard');
            else
              context.go('/home');
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        });
      },
    );
  }

  /// ✅ Widget tạo TextField
  Widget _buildTextField(
      String label, IconData icon, bool isPassword, Function(String) onChanged,
      {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true, // Làm form gọn lại
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blue.shade700, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
  Widget _buildSocialButton(String text, String logoPath,
      [VoidCallback? onPressed]) {
    return SizedBox(
      width: double.infinity,
      height: 45, // ✅ Giảm chiều cao nút
      child: ElevatedButton(
        onPressed: onPressed ??
            () {
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
