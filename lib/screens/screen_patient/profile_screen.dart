import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart'; // Sửa lại đường dẫn nếu cần

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _nameController.text = _user?['name'] ?? '';
    _phoneController.text = _user?['phone'] ?? '';
    _addressController.text = _user?['address'] ?? '';
    _genderController.text = _user?['gender'] ?? '';
    _insuranceController.text = _user?['healthInsurance'] ?? '';
    _avatarController.text = _user?['avatar'] ?? '';
  }

  Future<void> _updateProfile() async {
    try {
      final response = await ApiService.updateUserInfor(
        _user!['id'],
        _nameController.text,
        _phoneController.text,
        _addressController.text,
        _genderController.text,
        _insuranceController.text,
        _avatarController.text,
      );

      if (response == 'success') {
        final prefs = await SharedPreferences.getInstance();
        final updatedUser = {
          ..._user!,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'gender': _genderController.text,
          'healthInsurance': _insuranceController.text,
          'avatar': _avatarController.text,
        };
        await prefs.setString('user', jsonEncode(updatedUser));
        setState(() {
          _user = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin Cá Nhân'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông Tin Cơ Bản',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Họ và tên', Icons.person),
                    SizedBox(height: 10),
                    _buildTextField(_phoneController, 'Số điện thoại', Icons.phone, TextInputType.phone),
                    SizedBox(height: 10),
                    _buildTextField(_addressController, 'Địa chỉ', Icons.home),
                    SizedBox(height: 10),
                    _buildTextField(_genderController, 'Giới tính', Icons.wc),
                    SizedBox(height: 10),
                    _buildTextField(_insuranceController, 'Số BHYT', Icons.credit_card),
                    SizedBox(height: 10),
                    _buildTextField(_avatarController, 'Avatar URL', Icons.image),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Cập nhật thông tin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
    );
  }
}
