import 'package:flutter/material.dart';

class PatientManagementPage extends StatelessWidget {
  final List<String> actions = [
    'Thêm hồ sơ bệnh nhân',
    'Xoá bệnh nhân',
    'Sửa thông tin bệnh nhân',
    'Tìm kiếm bệnh nhân',
  ];

  final List<IconData> icons = [
    Icons.person_add,
    Icons.delete,
    Icons.edit,
    Icons.search,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Bệnh Nhân'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: Icon(icons[index], color: Colors.deepPurple),
              title: Text(actions[index],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Xử lý từng chức năng tại đây
              },
            ),
          );
        },
      ),
    );
  }
}
