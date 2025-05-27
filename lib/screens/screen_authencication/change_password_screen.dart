import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_page.dart'; // Import ChangePasswordPage

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', otp = '', name = '';
  bool isOtpVisible = false, isLoading = false, isOtpSent = false;

  // URL webhook từ n8n
  final String sendOtpUrl = 'http://localhost:5678/webhook-test/api_n8n/changePassword';
  final String verifyOtpUrl = 'http://localhost:5678/webhook-test/api-n8n/verify-otp';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Lấy email và name từ SharedPreferences
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('email') ?? '';
    final userName = prefs.getString('name') ?? '';
    print('Loaded email: $userEmail, name: $userName'); // Log để kiểm tra
    setState(() {
      email = userEmail;
      name = userName;
    });
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.red,
        ),
      );
      
    }
  }

  // Gửi yêu cầu OTP
  Future<void> sendOtp() async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy email người dùng'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('Sending OTP to: $email'); // Log email
      final response = await http.post(
        Uri.parse(sendOtpUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Response status: ${response.statusCode}'); // Log status
      print('Response body: ${response.body}'); // Log body

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true;
        });
        print('isOtpSent: $isOtpSent'); // Log trạng thái
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP đã được gửi qua email'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi OTP: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Xác thực OTP và chuyển sang trang đổi mật khẩu
  Future<void> verifyOtpAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(verifyOtpUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      setState(() {
        isLoading = false;
      });

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['valid'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChangePasswordPage(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Mã OTP không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building with isOtpSent: $isOtpSent'); // Log để kiểm tra
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/logo.png', height: 80),
                      const SizedBox(height: 10),
                      Text(
                        "Chăm sóc sức khỏe toàn diện - Vì bạn xứng đáng!",
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Đổi mật khẩu cho tài khoản: $name ($email)",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // Nút Nhận mã OTP và trường OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isOtpSent)
                            ElevatedButton(
                              onPressed: isLoading || email.isEmpty ? null : sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 20),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Nhận mã OTP", style: TextStyle(fontSize: 14)),
                            ),
                          if (isOtpSent) ...[
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Mã OTP',
                                  prefixIcon: Icon(Icons.vpn_key, color: Colors.blue.shade700),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        isOtpVisible ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        isOtpVisible = !isOtpVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !isOtpVisible,
                                validator: (value) => value!.isEmpty ? "Không được để trống" : null,
                                onChanged: (value) => otp = value,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: isLoading ? null : verifyOtpAndContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 20),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Tiếp tục", style: TextStyle(fontSize: 14)),
                            ),
                          ],
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
}