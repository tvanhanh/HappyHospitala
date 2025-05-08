import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // ✅ Màu nền dịu nhẹ
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10, // ✅ Hiệu ứng bóng mờ
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 400, // ✅ Giới hạn chiều rộng form
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

                      // ✅ Tiêu đề Quên mật khẩu
                      Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Nhập email của bạn để nhận hướng dẫn đặt lại mật khẩu.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 25),

                      // ✅ Nhập Email
                      _buildTextField(
                        label: "Email",
                        icon: Icons.email,
                        onChanged: (value) => email = value,
                      ),
                      SizedBox(height: 20),

                      // ✅ Nút Gửi yêu cầu
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text("Email đặt lại mật khẩu đã được gửi!"),
                                backgroundColor: Colors.green,
                              ),
                            );
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
                        child:
                            Text("Gửi yêu cầu", style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 15),

                      // ✅ Nút Back
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            Icon(Icons.arrow_back, color: Colors.blue.shade700),
                        label: Text("Quay lại",
                            style: TextStyle(
                                color: Colors.blue.shade700, fontSize: 16)),
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

  /// ✅ Widget tạo Input Email
  Widget _buildTextField(
      {required String label,
      required IconData icon,
      required Function(String) onChanged}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => !value!.contains("@") ? "Email không hợp lệ" : null,
      onChanged: onChanged,
    );
  }
}
