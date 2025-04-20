import 'package:flutter/material.dart';
import 'create_account_screen.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [
    {
      "name": "Dr. Nguyễn Văn A",
      "email": "a@hospital.com",
      "role": "Doctor",
      "active": true,
    },
    {
      "name": "Lê Thị B",
      "email": "b@hospital.com",
      "role": "Staff",
      "active": false,
    },
  ];

  void _toggleUserActive(int index) {
    setState(() {
      users[index]['active'] = !users[index]['active'];
    });
  }

  void _changeUserRole(int index) {
    setState(() {
      users[index]['role'] =
          users[index]['role'] == 'Doctor' ? 'Staff' : 'Doctor';
    });
  }

  void _createUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateUserScreenState()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Phân quyền & Bảo mật")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(user['role'] == 'Doctor'
                  ? Icons.medical_services
                  : Icons.admin_panel_settings),
              title: Text(user['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email']),
                  Text("Vai trò: ${user['role']}"),
                  Text(
                      "Trạng thái: ${user['active'] ? 'Hoạt động' : 'Bị khóa'}",
                      style: TextStyle(
                          color: user['active'] ? Colors.green : Colors.red)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'toggle') _toggleUserActive(index);
                  if (value == 'change_role') _changeUserRole(index);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'change_role',
                    child: Text('Chuyển vai trò'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child:
                        Text(user['active'] ? 'Vô hiệu hóa' : 'Kích hoạt lại'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: Icon(Icons.person_add),
        tooltip: 'Thêm người dùng',
      ),
    );
  }
}
