import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;

  const ChangePasswordPage({super.key, required this.email});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  
  String email = '';
  String oldPassword = '';
  String newPassword = '';
  String confirmPassword = '';
  
  bool isOldPassVisible = false;
  bool isNewPassVisible = false;
  bool isConfirmPassVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    email = widget.email;
    if (email.isEmpty) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '';
    });
  }

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
      final error = await ApiService.changePassword(email, oldPassword, newPassword, confirmPassword);
      setState(() {
        isLoading = false;
      });

      if (error == null) {
        showSnackbar("Đổi mật khẩu thành công");
        if (mounted) {
          context.go('/home');
        }
      } else {
        showSnackbar(error, isError: true);
      }
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
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                "Độ mạnh mật khẩu mới:",
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
      appBar: AppBar(
        title: const Text('Đổi mật khẩu tài khoản'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 8,
              shadowColor: Colors.blue.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      Text(
                        "Đổi Mật Khẩu",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Đổi mật khẩu định kỳ giúp bảo mật tài khoản tốt hơn",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      _buildPasswordField(
                        "Mật khẩu hiện tại",
                        isOldPassVisible,
                        (value) => oldPassword = value,
                        () => setState(() => isOldPassVisible = !isOldPassVisible),
                        validateStrict: false,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        "Mật khẩu mới",
                        isNewPassVisible,
                        (value) => setState(() => newPassword = value),
                        () => setState(() => isNewPassVisible = !isNewPassVisible),
                        validateStrict: true,
                      ),
                      _buildStrengthIndicator(),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        "Nhập lại mật khẩu mới",
                        isConfirmPassVisible,
                        (value) => confirmPassword = value,
                        () => setState(() => isConfirmPassVisible = !isConfirmPassVisible),
                        validateStrict: false,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : saveNewPassword,
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
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text("Hủy bỏ", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
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

  Widget _buildPasswordField(
    String label,
    bool isVisible,
    Function(String) onChanged,
    VoidCallback toggleVisibility, {
    bool validateStrict = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade400, size: 20),
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
        if (value == null || value.isEmpty) return "Không được để trống";
        if (validateStrict) {
          if (value.length < 8) return "Mật khẩu phải có ít nhất 8 ký tự";
          if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
            return "Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt (!@#\$&*~)";
          }
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}
