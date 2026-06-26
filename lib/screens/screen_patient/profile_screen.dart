import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _avatarUrl = '';
  bool _isUploadingAvatar = false;
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _identityCardController = TextEditingController();
  final _healthInsuranceController = TextEditingController();
  final _walletAddressController = TextEditingController();
  final _dobController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _gender = 'male';
  String _bloodType = 'O+';

  final List<String> _genders = ['male', 'female', 'other'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _identityCardController.dispose();
    _healthInsuranceController.dispose();
    _walletAddressController.dispose();
    _dobController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String _normalizeDate(String dateStr) {
    final clean = dateStr.trim();
    if (clean.isEmpty) return '';
    if (clean.contains('T')) {
      return clean.split('T')[0];
    }
    if (clean.contains(' ')) {
      return clean.split(' ')[0];
    }
    if (clean.length > 10) {
      return clean.substring(0, 10);
    }
    return clean;
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true) {
        final profile = res['profile'] ?? {};
        final user = res['user'] ?? {};

        _nameController.text = profile['name']?.toString() ?? '';
        _emailController.text = user['email']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _addressController.text = profile['address']?.toString() ?? '';
        _identityCardController.text = profile['identityCard']?.toString() ?? '';
        _healthInsuranceController.text = profile['healthInsurance']?.toString() ?? '';
        _walletAddressController.text = profile['walletAddress']?.toString() ?? '';

        final genderVal = profile['gender']?.toString() ?? 'male';
        _gender = _genders.contains(genderVal) ? genderVal : 'male';

        _dobController.text = _normalizeDate(profile['dateOfBirth']?.toString() ?? '');

        final bloodVal = profile['bloodType']?.toString() ?? 'O+';
        _bloodType = _bloodTypes.contains(bloodVal) ? bloodVal : 'O+';

        _allergiesController.text = profile['allergies']?.toString() ?? '';
        _chronicDiseasesController.text = profile['chronicDiseases']?.toString() ?? '';

        final emergency = profile['emergencyContact'];
        if (emergency is Map) {
          _emergencyNameController.text = emergency['name']?.toString() ?? '';
          _emergencyPhoneController.text = emergency['phone']?.toString() ?? '';
        }
        _avatarUrl = profile['avatar']?.toString() ?? '';
      }
    } catch (e) {
      print('Load error: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateProfile() async {
    final cleanDob = _normalizeDate(_dobController.text);
    if (cleanDob.isEmpty) {
      showSnackbar('Vui lòng chọn Ngày sinh!', isError: true);
      return;
    }
    if (_identityCardController.text.trim().isEmpty) {
      showSnackbar('Vui lòng nhập Số CCCD!', isError: true);
      return;
    }

    try {
      final data = {
        "profile": {
          "name": _nameController.text,
          "phone": _phoneController.text,
          "address": _addressController.text,
          "identityCard": _identityCardController.text,
          "healthInsurance": _healthInsuranceController.text,
          "walletAddress": _walletAddressController.text,
          "gender": _gender,
          "dateOfBirth": cleanDob,
          "bloodType": _bloodType,
          "allergies": _allergiesController.text,
          "chronicDiseases": _chronicDiseasesController.text,
          "emergencyContact": {
            "name": _emergencyNameController.text,
            "phone": _emergencyPhoneController.text,
          },
          "avatar": _avatarUrl
        }
      };

      await ApiService.updateProfile(data);
      
      setState(() {
        _dobController.text = cleanDob;
      });

      showSnackbar('Cập nhật thông tin thành công');
      _loadUser();
    } catch (e) {
      showSnackbar(e.toString(), isError: true);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final url = await _uploadToCloudinary(pickedFile);
      if (url != null) {
        setState(() {
          _avatarUrl = url;
        });
        await _updateProfile();
      }
    } catch (e) {
      showSnackbar('Tải ảnh đại diện thất bại: $e', isError: true);
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    const cloudName = 'dwlikpvh9';
    const uploadPreset = 'asset_clinic';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(resBody)['secure_url'] as String?;
    }
    throw Exception('Cloudinary error ${response.statusCode}: $resBody');
  }

  void _changePassword() {
    context.go('/auth/change_password_page');
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Xác nhận đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('role');
              await prefs.remove('userId');
              await prefs.remove('doctorId');
              await prefs.remove('name');
              await prefs.remove('email');
              await prefs.remove('avatarUrl');
              await prefs.remove('specialty');
              if (mounted) {
                context.go('/auth/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  String _getGenderText(String genderKey) {
    if (genderKey == 'male') return 'Nam';
    if (genderKey == 'female') return 'Nữ';
    return 'Khác';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hồ Sơ Sức Khỏe', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner & Avatar Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, Colors.blue.shade900],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 28, top: 10),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                          child: _avatarUrl.isEmpty
                              ? Icon(Icons.person, size: 55, color: Colors.blue.shade300)
                              : null,
                        ),
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : "Chưa cập nhật tên",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _emailController.text,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar section
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: themeColor,
                  labelColor: themeColor,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.badge_outlined), text: 'Cá nhân'),
                    Tab(icon: Icon(Icons.medical_services_outlined), text: 'Y tế'),
                    Tab(icon: Icon(Icons.contact_phone_outlined), text: 'Khẩn cấp'),
                  ],
                ),
              ),
            ),

            // Tab View and Form fields
            Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 380, // Chiều cao cố định phù hợp cho các Tab
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPersonalTab(),
                              _buildMedicalTab(),
                              _buildEmergencyTab(),
                            ],
                          ),
                        ),
                        const Divider(height: 32),
                        
                        // Update Profile Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.save_as_outlined, color: Colors.white),
                            label: const Text('Cập nhật thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Change Password Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _changePassword,
                            icon: Icon(Icons.lock_reset, color: themeColor),
                            label: Text('Đổi mật khẩu', style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: themeColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Personal Information Tab
  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildTextField("Họ và tên", _nameController, Icons.person_outline),
          const SizedBox(height: 12),
          _buildReadOnlyField("Địa chỉ Email", _emailController, Icons.mail_outline_rounded),
          const SizedBox(height: 12),
          _buildTextField("Số điện thoại", _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          // Date of birth with picker
          InkWell(
            onTap: () => _selectDate(context),
            child: IgnorePointer(
              child: _buildTextField("Ngày sinh", _dobController, Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _buildGenderDropdown(),
          const SizedBox(height: 12),
          _buildTextField("Số CCCD", _identityCardController, Icons.assignment_ind_outlined),
          const SizedBox(height: 12),
          _buildTextField("Địa chỉ hiện tại", _addressController, Icons.map_outlined),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Medical Information Tab
  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildBloodTypeDropdown(),
          const SizedBox(height: 12),
          _buildTextField("Số thẻ Bảo Hiểm Y Tế", _healthInsuranceController, Icons.health_and_safety_outlined),
          const SizedBox(height: 12),
          _buildTextField("Dị ứng (Thức ăn, thuốc...)", _allergiesController, Icons.warning_amber_rounded, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField("Bệnh lý nền (Tiểu đường, tim mạch...)", _chronicDiseasesController, Icons.coronavirus_outlined, maxLines: 2),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Emergency & Security Tab
  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Người liên hệ khẩn cấp",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField("Họ tên người liên hệ", _emergencyNameController, Icons.account_circle_outlined),
          const SizedBox(height: 12),
          _buildTextField("SĐT liên hệ khẩn cấp", _emergencyPhoneController, Icons.phone_in_talk_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Tài khoản & Blockchain",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField("Địa chỉ ví Blockchain (Bảo mật hồ sơ)", _walletAddressController, Icons.wallet_outlined),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Input Field Builders
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 16),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      style: TextStyle(color: Colors.grey.shade600),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _gender = val;
          });
        }
      },
      items: _genders.map((g) {
        return DropdownMenuItem<String>(
          value: g,
          child: Text(_getGenderText(g)),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: "Giới tính",
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(Icons.wc_outlined, color: Colors.blue.shade400, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _bloodType,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _bloodType = val;
          });
        }
      },
      items: _bloodTypes.map((b) {
        return DropdownMenuItem<String>(
          value: b,
          child: Text(b),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: "Nhóm máu",
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(Icons.bloodtype_outlined, color: Colors.blue.shade400, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
