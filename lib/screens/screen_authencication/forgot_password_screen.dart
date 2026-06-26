import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int _step = 1; // 1: Enter email/phone, 2: Enter OTP & New Password
  String emailOrPhone = '';
  String otp = '';
  String newPassword = '';
  String confirmPassword = '';
  
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  String? demoOtp;

  // For OTP inputs
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final result = await ApiService.sendOtpForgot(emailOrPhone);
        setState(() => isLoading = false);

        if (result == null || result.startsWith("success:")) {
          if (result != null && result.startsWith("success:")) {
            final isPhone = RegExp(r'^\d+$').hasMatch(emailOrPhone.trim());
            if (isPhone) {
              demoOtp = result.substring("success:".length);
            }
          }
          showSnackbar("Mã OTP đã được gửi đến $emailOrPhone", isError: false);
          setState(() {
            _step = 2;
          });
          _startTimer();

          // Auto-fill OTP for demo
          if (demoOtp != null && demoOtp!.length == 6) {
            for (int i = 0; i < 6; i++) {
              _otpControllers[i].text = demoOtp![i];
            }
          } else {
            for (int i = 0; i < 6; i++) {
              _otpControllers[i].clear();
            }
          }
        } else {
          showSnackbar(result, isError: true);
        }
      } catch (e) {
        setState(() => isLoading = false);
        showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      showSnackbar("Vui lòng nhập đủ 6 chữ số OTP", isError: true);
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (newPassword != confirmPassword) {
        showSnackbar("Mật khẩu xác nhận không khớp.", isError: true);
        return;
      }

      setState(() => isLoading = true);
      try {
        final result = await ApiService.resetPassword(emailOrPhone, otp, newPassword, confirmPassword);
        setState(() => isLoading = false);

        if (result == null) {
          showSnackbar("Đặt lại mật khẩu thành công!", isError: false);
          if (mounted) {
            context.go('/auth/login', extra: {'email': emailOrPhone, 'password': newPassword});
          }
        } else {
          showSnackbar(result, isError: true);
        }
      } catch (e) {
        setState(() => isLoading = false);
        showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
      }
    }
  }

  int get passwordStrengthScore {
    if (newPassword.isEmpty) return 0;
    int score = 0;
    if (newPassword.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(newPassword)) score++;
    if (RegExp(r'[a-z]').hasMatch(newPassword)) score++;
    if (RegExp(r'[0-9]').hasMatch(newPassword)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(newPassword)) score++;
    return score;
  }

  Widget _buildStrengthIndicator() {
    if (newPassword.isEmpty) return const SizedBox.shrink();

    final score = passwordStrengthScore;
    String strengthText = "Rất yếu";
    Color strengthColor = Colors.red.shade700;
    int activeBars = 0;

    if (score >= 5) {
      strengthText = "Mạnh (Chuẩn bảo mật)";
      strengthColor = Colors.green.shade600;
      activeBars = 3;
    } else if (score >= 3) {
      strengthText = "Trung bình";
      strengthColor = Colors.orange.shade700;
      activeBars = 2;
    } else {
      strengthText = "Yếu";
      strengthColor = Colors.red.shade700;
      activeBars = 1;
    }

    final bool hasLength = newPassword.length >= 8;
    final bool hasUpper = RegExp(r'[A-Z]').hasMatch(newPassword);
    final bool hasLower = RegExp(r'[a-z]').hasMatch(newPassword);
    final bool hasDigit = RegExp(r'[0-9]').hasMatch(newPassword);
    final bool hasSpecial = RegExp(r'[!@#\$&*~]').hasMatch(newPassword);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Độ mạnh mật khẩu:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
              ),
              Text(
                strengthText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: strengthColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final isActive = index < activeBars;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < 2 ? 6.0 : 0.0),
                  decoration: BoxDecoration(
                    color: isActive ? strengthColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequirementItem("Tối thiểu 8 ký tự", hasLength),
              const SizedBox(height: 4),
              _buildRequirementItem("Có chữ viết hoa (A-Z)", hasUpper),
              const SizedBox(height: 4),
              _buildRequirementItem("Có chữ viết thường (a-z)", hasLower),
              const SizedBox(height: 4),
              _buildRequirementItem("Có chữ số (0-9)", hasDigit),
              const SizedBox(height: 4),
              _buildRequirementItem("Có ký tự đặc biệt (!@#\$&*~)", hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: isMet ? Colors.green.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isMet ? Colors.green.shade800 : Colors.grey.shade600,
            fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 8,
                shadowColor: Colors.blue.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          _step == 1 ? "Quên mật khẩu" : "Đặt lại mật khẩu",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _step == 1
                              ? "Nhập Email hoặc Số điện thoại để nhận OTP"
                              : "Nhập mã OTP và thiết lập mật khẩu mới",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),

                        if (_step == 1) ...[
                          _buildEmailOrPhoneField(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleSendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text("Gửi mã OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          Text(
                            "Mã xác thực gửi đến: $emailOrPhone",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          _buildOtpBoxes(),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            "Mật khẩu mới",
                            Icons.lock_outline,
                            isPasswordVisible,
                            (value) => setState(() => newPassword = value),
                            () => setState(() => isPasswordVisible = !isPasswordVisible),
                          ),
                          _buildStrengthIndicator(),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            "Nhập lại mật khẩu mới",
                            Icons.lock_reset_outlined,
                            isConfirmPasswordVisible,
                            (value) => setState(() => confirmPassword = value),
                            () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text("Xác nhận đổi mật khẩu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _canResend
                              ? TextButton.icon(
                                  onPressed: () async {
                                    setState(() => isLoading = true);
                                    final result = await ApiService.sendOtpForgot(emailOrPhone);
                                    setState(() => isLoading = false);
                                    if (result == null || result.startsWith("success:")) {
                                      if (result != null && result.startsWith("success:")) {
                                        final isPhone = RegExp(r'^\d+$').hasMatch(emailOrPhone.trim());
                                        if (isPhone) {
                                          demoOtp = result.substring("success:".length);
                                          // Auto-fill OTP
                                          for (int i = 0; i < 6; i++) {
                                            _otpControllers[i].text = demoOtp![i];
                                          }
                                        } else {
                                          for (int i = 0; i < 6; i++) {
                                            _otpControllers[i].clear();
                                          }
                                        }
                                      }
                                      showSnackbar("Mã OTP đã được gửi lại", isError: false);
                                      _startTimer();
                                    } else {
                                      showSnackbar(result, isError: true);
                                    }
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text("Gửi lại mã OTP"),
                                  style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                                )
                              : Text(
                                  "Gửi lại mã sau ${_secondsRemaining}s",
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                        ],

                        const SizedBox(height: 20),
                        // Back to login
                        TextButton.icon(
                          onPressed: () => context.go('/auth/login'),
                          icon: Icon(Icons.arrow_back, color: Colors.blue.shade700, size: 18),
                          label: Text("Quay lại đăng nhập", style: TextStyle(color: Colors.blue.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildEmailOrPhoneField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Email hoặc Số điện thoại",
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(Icons.contact_mail_outlined, color: Colors.blue.shade400, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Không được để trống";
        final val = value.trim();
        final isPhone = RegExp(r'^\d+$').hasMatch(val);
        if (isPhone) {
          if (val.length != 10 || !val.startsWith('0')) {
            return "Số điện thoại phải gồm 10 chữ số và bắt đầu bằng số 0";
          }
        } else {
          if (!val.endsWith("@gmail.com")) {
            return "Vui lòng nhập Số điện thoại hoặc Email đuôi @gmail.com";
          }
        }
        return null;
      },
      onChanged: (value) => emailOrPhone = value,
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 44,
          height: 50,
          child: Focus(
            onKeyEvent: (node, event) {
              if (event.logicalKey.keyLabel == "Backspace" && _otpControllers[index].text.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
                _otpControllers[index - 1].clear();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue.shade900),
              decoration: InputDecoration(
                counterText: "",
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else {
                    _otpFocusNodes[index].unfocus();
                  }
                } else {
                  if (index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPasswordField(String label, IconData icon, bool isVisible, Function(String) onChanged, VoidCallback toggleVisibility) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade500, size: 20),
          onPressed: toggleVisibility,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: !isVisible,
      validator: (value) {
        if (value == null || value.length < 8) return "Mật khẩu phải có ít nhất 8 ký tự";
        if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
          return "Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt (!@#\$&*~)";
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}
