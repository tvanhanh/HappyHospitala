import 'package:flutter/material.dart';

class DepartmentManagement extends StatefulWidget {
  @override
  _DepartmentManagementState createState() => _DepartmentManagementState();
}

class _DepartmentManagementState extends State<DepartmentManagement> {
  List<Map<String, String>> departments = [
    {'name': 'Khoa Nội', 'description': 'Chăm sóc các bệnh nội khoa'},
    {'name': 'Khoa Ngoại', 'description': 'Phẫu thuật và điều trị ngoại khoa'},
  ];

  void _addDepartment() {
    // TODO: Hiện dialog hoặc chuyển màn hình thêm phòng ban mới
  }

  void _editDepartment(int index) {
    // TODO: Hiện dialog hoặc chuyển màn hình chỉnh sửa phòng ban
  }

  void _deleteDepartment(int index) {
    setState(() {
      departments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý phòng ban'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addDepartment,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(dept['name'] ?? ''),
              subtitle: Text(dept['description'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editDepartment(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDepartment(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
