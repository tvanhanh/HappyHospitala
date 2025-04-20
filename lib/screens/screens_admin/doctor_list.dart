import 'package:flutter/material.dart';

class DoctorListScreen extends StatefulWidget {
  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Nguyễn Văn A',
      'specialty': 'Tim mạch',
      'email': 'a@example.com',
      'active': true,
    },
    {
      'name': 'Dr. Trần Thị B',
      'specialty': 'Nội tiết',
      'email': 'b@example.com',
      'active': false,
    },
  ];

  void toggleStatus(int index) {
    setState(() {
      doctors[index]['active'] = !doctors[index]['active'];
    });
  }

  void addDoctor() {
    // TODO: mở form thêm bác sĩ
  }

  void editDoctor(int index) {
    // TODO: sửa thông tin bác sĩ
  }

  void deleteDoctor(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xác nhận xoá"),
        content: Text("Bạn có chắc muốn xoá bác sĩ này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          TextButton(
            onPressed: () {
              setState(() {
                doctors.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      body: ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.person, size: 40),
              title: Text(doctor['name']),
              subtitle: Text('${doctor['specialty']} • ${doctor['email']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    editDoctor(index);
                  } else if (value == 'delete') {
                    deleteDoctor(index);
                  } else if (value == 'toggle') {
                    toggleStatus(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  PopupMenuItem(value: 'toggle', child: Text(doctor['active'] ? 'Vô hiệu hoá' : 'Kích hoạt')),
                  PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
              ),
              tileColor: doctor['active'] ? Colors.white : Colors.grey.shade200,
            ),
          );
        },
      ),
    );
  }
}
