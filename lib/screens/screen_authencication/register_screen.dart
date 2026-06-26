import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  
  String name = '';
  String emailOrPhone = '';
  String password = '';
  String confirmPassword = '';
  
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

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

  Future<void> _handleRegisterClick() async {
    if (_formKey.currentState!.validate()) {
      if (password != confirmPassword) {
        showSnackbar("Mật khẩu xác nhận không khớp.", isError: true);
        return;
      }

      setState(() => isLoading = true);
      
      try {
        // Gửi yêu cầu gửi mã OTP
        final result = await ApiService.sendOtpRegister(emailOrPhone);
        
        setState(() => isLoading = false);

        if (result == null || result.startsWith("success:")) {
          String? demoOtp;
          if (result != null && result.startsWith("success:")) {
            final isPhone = RegExp(r'^\d+$').hasMatch(emailOrPhone.trim());
            if (isPhone) {
              demoOtp = result.substring("success:".length);
            }
          }
          showSnackbar("Mã OTP đã được gửi đến $emailOrPhone", isError: false);
          // Hiển thị Dialog nhập OTP
          _showOtpDialog(demoOtp: demoOtp);
        } else {
          showSnackbar(result, isError: true);
        }
      } catch (e) {
        setState(() => isLoading = false);
        logger.e("Lỗi exception: $e");
        showSnackbar("Đã xảy ra lỗi hệ thống", isError: true);
      }
    }
  }

  void _showOtpDialog({String? demoOtp}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ModernOtpDialog(
          emailOrPhone: emailOrPhone,
          initialOtp: demoOtp,
          onResend: () async {
            final result = await ApiService.sendOtpRegister(emailOrPhone);
            if (result != null && !result.startsWith("success:")) {
              return result;
            }
            return null; // success
          },
          onVerify: (otp) async {
            return await ApiService.registerUser(
                name, emailOrPhone, password, confirmPassword, otp);
          },
          onSuccess: () {
            showSnackbar("Đăng ký thành công! Hãy đăng nhập.", isError: false);
            context.go('/auth/login', extra: {'email': emailOrPhone, 'password': password});
          },
        );
      },
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
              constraints: const BoxConstraints(maxWidth: 450), // Giới hạn độ rộng giao diện đẹp cho cả Web
              child: Card(
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // Giảm từ 32 xuống 24
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo (Thu nhỏ lại)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              height: 50, // Giảm từ 80 xuống 50
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Giảm từ 24
                        
                        // Title
                        Text(
                          "Tạo Tài Khoản",
                          style: TextStyle(
                            fontSize: 24, // Giảm từ 28
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Nhập thông tin của bạn để bắt đầu",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20), // Giảm từ 32

                        // Inputs (Giảm khoảng cách)
                        _buildTextField(
                          "Họ và tên", 
                          Icons.person_outline, 
                          false, 
                          (value) => name = value,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildEmailField(
                          "Email hoặc Số điện thoại", 
                          Icons.contact_mail_outlined, 
                          (value) => emailOrPhone = value,
                        ),
                        const SizedBox(height: 12),

                        _buildPasswordField(
                            "Mật khẩu (ít nhất 8 ký tự)",
                            Icons.lock_outline,
                            isPasswordVisible,
                            (value) {
                              setState(() {
                                password = value;
                              });
                            }, () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        }),
                        _buildStrengthIndicator(),
                        const SizedBox(height: 12),

                        _buildPasswordField(
                            "Nhập lại mật khẩu",
                            Icons.lock_reset_outlined,
                            isConfirmPasswordVisible,
                            (value) {
                              setState(() {
                                confirmPassword = value;
                              });
                            }, () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        }),
                        const SizedBox(height: 20),
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 48, // Giảm từ 52
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegisterClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            child: isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Đăng ký", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Footer Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Đã có tài khoản?", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                            TextButton(
                              onPressed: () => context.go('/auth/login'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text("Đăng nhập", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );
  }

  // Helpers
  Widget _buildTextField(String label, IconData icon, bool isPassword, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
        isDense: true, 
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: isPassword,
      validator: (value) => value!.trim().isEmpty ? "Không được để trống" : null,
      onChanged: onChanged,
    );
  }

  Widget _buildEmailField(String label, IconData icon, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
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
      onChanged: onChanged,
    );
  }

  int get passwordStrengthScore {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;
    return score;
  }

  Widget _buildStrengthIndicator() {
    if (password.isEmpty) return const SizedBox.shrink();

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

    final bool hasLength = password.length >= 8;
    final bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    final bool hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final bool hasSpecial = RegExp(r'[!@#\$&*~]').hasMatch(password);

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
          // 3 Segmented Strength Bars
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
          // Requirements checklist
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
        // Kí tự in hoa, số, kí tự đặc biệt
        if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
          return "Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt (!@#\$&*~)";
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

class ModernOtpDialog extends StatefulWidget {
  final String emailOrPhone;
  final Future<String?> Function() onResend;
  final Future<String?> Function(String otp) onVerify;
  final Function() onSuccess;
  final String? initialOtp;

  const ModernOtpDialog({
    super.key,
    required this.emailOrPhone,
    required this.onResend,
    required this.onVerify,
    required this.onSuccess,
    this.initialOtp,
  });

  @override
  State<ModernOtpDialog> createState() => _ModernOtpDialogState();
}

class _ModernOtpDialogState extends State<ModernOtpDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Tự động điền mã OTP và xác thực (dành cho Demo)
    if (widget.initialOtp != null && widget.initialOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.initialOtp![i];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVerify();
      });
    }
  }

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
      _errorMessage = "";
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
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final otp = _otpCode;
    if (otp.length != 6) {
      setState(() {
        _errorMessage = "Vui lòng nhập đủ 6 chữ số.";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = "";
    });

    final error = await widget.onVerify(otp);

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
    });

    if (error == null) {
      Navigator.pop(context); // Đóng dialog
      widget.onSuccess();
    } else {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.15),
                  blurRadius: 25,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_outlined,
                    size: 38,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Xác thực OTP",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Vui lòng nhập mã OTP gồm 6 chữ số đã được gửi đến:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.emailOrPhone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      height: 54,
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event.logicalKey.keyLabel == "Backspace" && _controllers[index].text.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                            _controllers[index - 1].clear();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          autofocus: index == 0,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.blue.shade900,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                                _handleVerify();
                              }
                            } else {
                              if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                _canResend
                    ? TextButton.icon(
                        onPressed: () async {
                          final error = await widget.onResend();
                          if (error == null) {
                            _startTimer();
                          } else {
                            setState(() {
                              _errorMessage = error;
                            });
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Gửi lại mã OTP"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    : Text(
                        "Gửi lại mã sau ${_secondsRemaining}s",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isVerifying ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
