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
      backgroundColor: Colors.grey.shade100, // ✅ Nền dịu nhẹ
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10, // ✅ Hiệu ứng bóng mờ
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 400, // ✅ Giới hạn chiều rộng
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

                      // ✅ Tiêu đề Đăng ký
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

                      // ✅ Họ và tên
                      _buildTextField("Họ và tên", Icons.person, false,
                          (value) => name = value),
                      SizedBox(height: 15),

                      // ✅ Email
                      _buildTextField("Email", Icons.email, false,
                          (value) => email = value),
                      SizedBox(height: 15),

                      // ✅ Mật khẩu
                      _buildPasswordField("Mật khẩu", isPasswordVisible,
                          (value) => password = value, () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      }),
                      SizedBox(height: 15),

                      // ✅ Nhập lại mật khẩu
                      _buildPasswordField(
                          "Nhập lại mật khẩu",
                          isConfirmPasswordVisible,
                          (value) => confirmPassword = value, () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      }),
                      SizedBox(height: 20),

                      // ✅ Nút Đăng ký
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                         
                            if (password != confirmPassword) {
                              if (!context.mounted) return;
                              showSnackbar("Mật khẩu không khớp",
                                  isError: true);
                              return;
                            }
                            try{

                            final error = await ApiService.registerUser(
                                name, email, password,confirmPassword);
                              
                            if (error == null) {
                              showSnackbar("Đăng ký thành công");
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LoginScreen()));
                            } else {
                              showSnackbar(error, isError: true);
                            }
                            }catch(e){
                              logger.e("Lỗi exception: $e");
                              showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 80),
                        ),
                        child: Text("Đăng ký", style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 15),

                      // ✅ Đã có tài khoản? Đăng nhập ngay
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Đã có tài khoản?",
                              style: TextStyle(color: Colors.grey.shade700)),
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

  /// ✅ Widget tạo Input TextField
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

  /// ✅ Widget tạo Input Mật khẩu
  Widget _buildPasswordField(String label, bool isVisible,
      Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
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
      validator: (value) =>
          value!.length < 6 ? "Mật khẩu ít nhất 6 ký tự" : null,
      onChanged: onChanged,
    );
  }
}
