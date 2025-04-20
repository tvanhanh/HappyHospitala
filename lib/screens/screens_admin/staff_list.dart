import 'package:flutter/material.dart';

class StaffManagement extends StatefulWidget {
  @override
  _StaffManagementState createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  List<Map<String, String>> staffList = [
    {
      'name': 'Nguyễn Văn A',
      'role': 'Bác sĩ',
      'email': 'a@example.com',
    },
    {
      'name': 'Trần Thị B',
      'role': 'Lễ tân',
      'email': 'b@example.com',
    },
  ];

  void _addStaff() {
    // TODO: Mở dialog hoặc điều hướng đến màn hình thêm staff
  }

  void _editStaff(int index) {
    // TODO: Mở dialog hoặc điều hướng đến màn hình chỉnh sửa staff
  }

  void _deleteStaff(int index) {
    setState(() {
      staffList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nhân viên'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addStaff,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: staffList.length,
        itemBuilder: (context, index) {
          final staff = staffList[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(staff['name']![0]),
              ),
              title: Text(staff['name'] ?? ''),
              subtitle: Text('${staff['role']} - ${staff['email']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editStaff(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStaff(index),
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
