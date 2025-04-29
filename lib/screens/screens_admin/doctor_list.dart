import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorListScreen extends StatefulWidget {
  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> doctors = [];
  String? selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
    fetchDoctors();
  }

  Future<void> fetchDepartments() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/departments'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          departments = data
              .map((d) => {
                    'id': d['_id'],
                    'name': d['departmentName'],
                  })
              .toList();
        });
      } else {
        print('Lỗi khi lấy phòng ban: ${response.body}');
      }
    } catch (e) {
      print('Lỗi mạng khi lấy phòng ban: $e');
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/doctors'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          doctors = data.map((d) {
            return {
              'name': d['name'],
              'departmentName': d['department']?['departmentName'] ?? '',
              'active': d['active'] ?? true,
            };
          }).toList();
        });
      } else {
        print('Lỗi khi lấy bác sĩ: ${response.body}');
      }
    } catch (e) {
      print('Lỗi mạng khi lấy bác sĩ: $e');
    }
  }

  void addDoctor() {
    final TextEditingController nameController = TextEditingController();
    selectedDepartmentId = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm bác sĩ mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Tên bác sĩ'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Phòng ban'),
                value: selectedDepartmentId,
                items: departments.map((dept) {
                  return DropdownMenuItem<String>(
                    value: dept['id'],
                    child: Text(dept['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedDepartmentId = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty || selectedDepartmentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                  );
                  return;
                }

                final result = await createDoctor(name, selectedDepartmentId!);
                if (result == 'success') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm bác sĩ thành công')),
                  );
                  fetchDoctors(); // cập nhật lại danh sách
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<String> createDoctor(String name, String departmentId) async {
    final url = Uri.parse('http://localhost:3000/admin/create-doctor');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'departmentId': departmentId,
      }),
    );

    if (response.statusCode == 201) return 'success';
    return 'Lỗi: ${response.body}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách bác sĩ"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addDoctor,
            tooltip: 'Thêm bác sĩ',
          )
        ],
      ),
      body: doctors.isEmpty
          ? Center(child: Text('Chưa có bác sĩ nào'))
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.person, size: 40),
                    title: Text(doctor['name']),
                    subtitle: Text(doctor['departmentName']),
                    trailing: Icon(
                      doctor['active'] ? Icons.check_circle : Icons.cancel,
                      color: doctor['active'] ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
