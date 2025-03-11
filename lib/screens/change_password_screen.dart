import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String oldPassword = '', newPassword = '', confirmPassword = '';
  bool isOldPassVisible = false,
      isNewPassVisible = false,
      isConfirmPassVisible = false;

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
                width: 400,
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

                      Text(
                        "Nhập thông tin bên dưới để đổi mật khẩu",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 25),

                      // ✅ Mật khẩu cũ
                      _buildPasswordField("Mật khẩu cũ", isOldPassVisible,
                          (value) => oldPassword = value, () {
                        setState(() {
                          isOldPassVisible = !isOldPassVisible;
                        });
                      }),
                      SizedBox(height: 15),

                      // ✅ Mật khẩu mới
                      _buildPasswordField("Mật khẩu mới", isNewPassVisible,
                          (value) => newPassword = value, () {
                        setState(() {
                          isNewPassVisible = !isNewPassVisible;
                        });
                      }),
                      SizedBox(height: 15),

                      // ✅ Nhập lại mật khẩu mới
                      _buildPasswordField(
                          "Nhập lại mật khẩu",
                          isConfirmPassVisible,
                          (value) => confirmPassword = value, () {
                        setState(() {
                          isConfirmPassVisible = !isConfirmPassVisible;
                        });
                      }),
                      SizedBox(height: 20),

                      // ✅ Nút Đổi mật khẩu
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (newPassword == confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Đổi mật khẩu thành công"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Mật khẩu mới không khớp"),
                                  backgroundColor: Colors.red,
                                ),
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
                              vertical: 12, horizontal: 80),
                        ),
                        child: Text("Đổi mật khẩu",
                            style: TextStyle(fontSize: 16)),
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

  /// ✅ Widget tạo Input mật khẩu
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
      validator: (value) => value!.isEmpty ? "Không được để trống" : null,
      onChanged: onChanged,
    );
  }
}
