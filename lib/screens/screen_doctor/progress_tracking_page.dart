import 'package:flutter/material.dart';

class ProgressTrackingPage extends StatelessWidget {
  final List<Map<String, dynamic>> progressData = [
    {
      'name': 'Nguyễn Văn A',
      'status': 'Ổn định',
      'lastUpdate': '05/05/2025',
      'note': 'Đã giảm liều thuốc theo phác đồ'
    },
    {
      'name': 'Trần Thị B',
      'status': 'Cần theo dõi',
      'lastUpdate': '04/05/2025',
      'note': 'Đường huyết chưa ổn định, cần kiểm tra lại'
    },
    {
      'name': 'Lê Văn C',
      'status': 'Tốt lên',
      'lastUpdate': '02/05/2025',
      'note': 'Phản ứng tích cực với thuốc mới'
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Tốt lên':
        return Colors.green;
      case 'Ổn định':
        return Colors.orange;
      case 'Cần theo dõi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theo Dõi Tiến Trình Bệnh Nhân'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: progressData.length,
        itemBuilder: (context, index) {
          final patient = progressData[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: getStatusColor(patient['status']),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(patient['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái: ${patient['status']}'),
                  Text('Cập nhật gần nhất: ${patient['lastUpdate']}'),
                  Text('Ghi chú: ${patient['note']}'),
                ],
              ),
              isThreeLine: true,
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Chuyển đến chi tiết nếu cần
              },
            ),
          );
        },
      ),
    );
  }
}
