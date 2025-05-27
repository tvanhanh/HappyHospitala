import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;

  const ChangePasswordPage({super.key, required this.email});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String newPassword = '', confirmPassword = '';
  bool isNewPassVisible = false,
      isConfirmPassVisible = false,
      isLoading = false;

  Future<void> saveNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPassword != confirmPassword) {
      showSnackbar("Mật khẩu mới không khớp", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Gọi API đổi mật khẩu, truyền vào email + mật khẩu mới
      final response =
          await ApiService.changePassWord(widget.email, newPassword);

      setState(() {
        isLoading = false;
      });

      
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackbar("Lỗi kết nối: $e", isError: true);
    }
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Nhập mật khẩu mới",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        "Mật khẩu mới",
                        isNewPassVisible,
                        (value) => newPassword = value,
                        () {
                          setState(() {
                            isNewPassVisible = !isNewPassVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordField(
                        "Nhập lại mật khẩu",
                        isConfirmPassVisible,
                        (value) => confirmPassword = value,
                        () {
                          setState(() {
                            isConfirmPassVisible = !isConfirmPassVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : saveNewPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 80),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Đổi mật khẩu",
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

  Widget _buildPasswordField(String label, bool isVisible,
      Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
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
