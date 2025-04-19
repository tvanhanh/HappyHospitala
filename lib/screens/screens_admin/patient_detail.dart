import 'package:flutter/material.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, String> patient;

  const PatientDetailScreen({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết bệnh nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(height: 16),
            Text(
              patient['name'] ?? '',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildInfoRow("Ngày sinh", patient['dob']),
            _buildInfoRow("Giới tính", patient['gender']),
            _buildInfoRow("Số điện thoại", patient['phone']),
            _buildInfoRow("Địa chỉ", patient['address']),
            SizedBox(height: 30),

            // Nút chức năng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Chuyển sang màn sửa
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Xác nhận xoá
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Xác nhận xoá"),
                        content: Text("Bạn có chắc muốn xoá bệnh nhân này?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Huỷ")),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context); // quay về danh sách
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Đã xoá bệnh nhân"),
                                    backgroundColor: Colors.red),
                              );
                            },
                            child: Text("Xoá", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Xoá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
              child:
                  Text(value ?? '', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
