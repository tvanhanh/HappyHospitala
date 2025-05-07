import 'package:flutter/material.dart';

class ClassificationResultsPage extends StatelessWidget {
  final List<Map<String, dynamic>> results = [
    {
      'name': 'Nguyễn Văn A',
      'risk': 'Cao',
      'description': 'Nguy cơ cao cần theo dõi sát sao',
      'color': Colors.redAccent,
    },
    {
      'name': 'Trần Thị B',
      'risk': 'Trung bình',
      'description': 'Cần tái khám định kỳ và theo dõi thêm',
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Lê Văn C',
      'risk': 'Thấp',
      'description': 'Tình trạng ổn định, theo dõi thông thường',
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Phân Loại Bệnh Nhân'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: result['color'],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                result['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mức độ rủi ro: ${result['risk']}',
                      style: TextStyle(
                          color: result['color'], fontWeight: FontWeight.w600)),
                  Text(result['description']),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Hiển thị chi tiết bệnh nhân nếu cần
              },
            ),
          );
        },
      ),
    );
  }
}
