import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'login_screen.dart';
import 'package:logger/logger.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  String name = '', email = '', password = '', confirmPassword = '';
  bool isPasswordVisible = false, isConfirmPasswordVisible = false;

  void showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor:
              isError ? Colors.red.shade700 : Colors.green.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Giới hạn chiều rộng tối đa cho Card (Responsive)
    final cardWidth = screenWidth > 450 ? 450.0 : screenWidth * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        // ✅ Đảm bảo nội dung nằm trong vùng an toàn
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
            child: SizedBox(
              width: cardWidth, // Áp dụng chiều rộng responsive
              child: Card(
                elevation: 15, // Tăng độ nổi
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)), // Bo góc rõ ràng
                child: Padding(
                  padding: EdgeInsets.all(30), // Tăng padding bên trong
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- LOGO TRÒN VÀ SLOGAN ---
                        ClipOval(
                          // ✅ Áp dụng ClipOval cho logo tròn
                          child: Image.asset(
                            'assets/logo.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 15), // ✅ Khoảng cách hợp lý
                        Text(
                          "Chăm sóc sức khỏe toàn diện ",
                          style: TextStyle(
                              fontSize: 15, // Tăng font size một chút
                              fontStyle: FontStyle.italic,
                              color: Colors.lightBlue.shade700,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: 20), // ✅ Khoảng cách lớn hơn cho tiêu đề

                        // --- TIÊU ĐỀ ĐĂNG KÝ ---
                        Text(
                          "Tạo Tài Khoản",
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade900),
                        ),
                        Text(
                          "Nhập thông tin của bạn để bắt đầu",
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 20), // ✅ Khoảng cách trước Input

                        // --- INPUT FIELDS ---
                        _buildTextField("Họ và tên", Icons.person, false,
                            (value) => name = value!),
                        SizedBox(height: 10), // ✅ Khoảng cách
                        _buildTextField("Email", Icons.email, false,
                            (value) => email = value!),
                        SizedBox(height: 10), // ✅ Khoảng cách

                        // ✅ Mật khẩu (Sử dụng hàm đã tối ưu bên dưới)
                        _buildPasswordField(
                            "Mật khẩu (ít nhất 6 ký tự)",
                            Icons.lock,
                            isPasswordVisible,
                            (value) => password = value!, () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        }),
                        SizedBox(height: 10), // ✅ Khoảng cách

                        // ✅ Nhập lại mật khẩu (Sử dụng hàm đã tối ưu bên dưới)
                        _buildPasswordField(
                            "Nhập lại mật khẩu",
                            Icons.lock_reset, // Icon khác biệt hơn
                            isConfirmPasswordVisible,
                            (value) => confirmPassword = value!, () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        }),
                        SizedBox(height: 20), // ✅ Khoảng cách trước nút

                        // --- Nút Đăng ký ---
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Chiều cao nút chuẩn
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (password != confirmPassword) {
                                  if (!context.mounted) return;
                                  showSnackbar("Mật khẩu xác nhận không khớp.",
                                      isError: true);
                                  return;
                                }

                                try {
                                  final error = await ApiService.registerUser(
                                      name, email, password, confirmPassword);

                                  if (error == null) {
                                    showSnackbar(
                                        "Đăng ký thành công! Hãy đăng nhập.",
                                        isError: false);
                                    if (!context.mounted) return;
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => LoginScreen()));
                                  } else {
                                    showSnackbar(error, isError: true);
                                  }
                                } catch (e) {
                                  logger.e("Lỗi exception: $e");
                                  showSnackbar("Đã xảy ra lỗi hệ thống",
                                      isError: true);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: Text("Đăng ký",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: 25), // ✅ Khoảng cách

                        // --- Đã có tài khoản? Đăng nhập ngay ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Đã có tài khoản?",
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 15)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()));
                              },
                              child: Text("Đăng nhập ngay",
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: 20), // ✅ Khoảng đệm cuối cùng (Giữ an toàn)
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

  /// ✅ Widget tạo Input TextField Cơ bản
  Widget _buildTextField(String label, IconData icon, bool isPassword,
      Function(String) onChanged) {
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

  /// ✅ Widget tạo Input Mật khẩu (Đã tối ưu cho màn hình đăng ký)
  Widget _buildPasswordField(String label, IconData icon, bool isVisible,
      Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: !isVisible,
      validator: (value) {
        if (value == null || value.length < 6) {
          return "Mật khẩu phải có ít nhất 6 ký tự";
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}
