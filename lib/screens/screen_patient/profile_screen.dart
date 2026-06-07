import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _avatarUrl = '';
  bool _isUploadingAvatar = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _identityCardController = TextEditingController();
  final _healthInsuranceController = TextEditingController();
  final _walletAddressController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
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

        _nameController.text = profile['name']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _addressController.text = profile['address']?.toString() ?? '';
        _identityCardController.text =
            profile['identityCard']?.toString() ?? '';
        _healthInsuranceController.text =
            profile['healthInsurance']?.toString() ?? '';
        _walletAddressController.text =
            profile['walletAddress']?.toString() ?? '';

        _genderController.text = profile['gender']?.toString() ?? '';
        _dobController.text = _normalizeDate(profile['dateOfBirth']?.toString() ?? '');
        _bloodTypeController.text = profile['bloodType']?.toString() ?? '';
        _allergiesController.text = profile['allergies']?.toString() ?? '';
        _chronicDiseasesController.text =
            profile['chronicDiseases']?.toString() ?? '';

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

  Future<void> _updateProfile() async {
    final cleanDob = _normalizeDate(_dobController.text);
    if (cleanDob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập Ngày sinh!')),
      );
      return;
    }
    if (_identityCardController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập Số CCCD!')),
      );
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
          "gender": _genderController.text,
          "dateOfBirth": cleanDob,
          "bloodType": _bloodTypeController.text,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
      _loadUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải ảnh đại diện thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    const cloudName = 'dwlikpvh9';
    const uploadPreset = 'asset_clinic';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
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

  Future<void> _changePassword() async {
    // Left empty or keep dummy implementation since ApiService doesn't export change password explicitly,
    // but typically this would hit another route.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đổi mật khẩu đang cập nhật')),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ Sơ Sức Khỏe'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập Nhật Thông Tin',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _avatarUrl.isNotEmpty
                                  ? NetworkImage(_avatarUrl)
                                  : null,
                              child: _avatarUrl.isEmpty
                                  ? Icon(Icons.person,
                                      size: 55, color: Colors.grey[600])
                                  : null,
                            ),
                          ),
                          if (_isUploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _identityCardController,
                      decoration: InputDecoration(
                        labelText: 'Số CCCD (Bắt buộc) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Ngày sinh (YYYY-MM-DD) (Bắt buộc) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _genderController,
                      decoration: InputDecoration(
                        labelText: 'Giới tính',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _bloodTypeController,
                      decoration: InputDecoration(
                        labelText: 'Nhóm máu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bloodtype),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _healthInsuranceController,
                      decoration: InputDecoration(
                        labelText: 'Số BHYT (Tùy chọn)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.health_and_safety),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _walletAddressController,
                      decoration: InputDecoration(
                        labelText: 'Khóa Blockchain (Tùy chọn)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wallet),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emergencyNameController,
                            decoration: InputDecoration(
                              labelText: 'Người liên hệ khẩn cấp',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.contact_emergency),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _emergencyPhoneController,
                            decoration: InputDecoration(
                              labelText: 'SĐT Khẩn cấp',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_in_talk),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _chronicDiseasesController,
                      decoration: InputDecoration(
                        labelText: 'Bệnh nền (VD: Tiểu đường type 2...)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.coronavirus),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _allergiesController,
                      decoration: InputDecoration(
                        labelText: 'Dị ứng',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Cập nhật thông tin',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Đổi Mật Khẩu',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: Text('Đổi mật khẩu',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
