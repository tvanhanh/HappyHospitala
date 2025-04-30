import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_doctors.dart';
import '../../services/api_department.dart';

class AddDoctorScreen extends StatefulWidget {
  @override
  _AddDoctorScreenState createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();

  List<Map<String, dynamic>> departments = [];
  String? selectedDepartmentId;
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final data = await DepartmentService.getDepartments();
      setState(() {
        departments = data;
      });
    } catch (e) {
      print('Lỗi khi lấy phòng ban: $e');
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> saveDoctor() async {
    final doctorName = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final specialization = specializationController.text.trim();

    if (doctorName.isEmpty || selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập tên và chọn phòng ban")),
      );
      return;
    }

    final avatar = _image?.path ?? "";

    final result = await DoctorService.addDoctor(
      doctorName,
      email,
      phone,
      address,
      selectedDepartmentId!,
      specialization,
      avatar,
    );

    if (!context.mounted) return;
    if (result == 'success') {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm bác sĩ')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: _image == null
                  ? CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.camera_alt, size: 30),
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundImage: FileImage(_image!),
                    ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Tên bác sĩ'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Số điện thoại'),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Địa chỉ'),
            ),
            TextField(
              controller: specializationController,
              decoration: InputDecoration(labelText: 'Chuyên khoa'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Phòng ban'),
              value: selectedDepartmentId,
              items: departments.map((dept) {
                final id = dept['id']?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(dept['departmentName']?.toString()??'Không rõ tên phòng ban'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDepartmentId = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveDoctor,
              child: Text('Lưu'),
            )
          ],
        ),
      ),
    );
  }
}
