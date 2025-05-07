import 'package:flutter/material.dart';

class PrescriptionPage extends StatelessWidget {
  final List<Map<String, String>> prescriptions = [
    {
      'patient': 'Nguyễn Văn A',
      'type': 'Đơn thuốc',
      'note': 'Paracetamol 500mg, uống sau ăn',
    },
    {
      'patient': 'Trần Thị B',
      'type': 'Xét nghiệm',
      'note': 'Xét nghiệm máu tổng quát',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi Đơn Thuốc / Xét Nghiệm'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final item = prescriptions[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  item['type'] == 'Đơn thuốc' ? Icons.medication : Icons.science,
                  color: Colors.green,
                ),
                title: Text(item['patient']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loại: ${item['type']}'),
                    Text('Ghi chú: ${item['note']}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Xử lý chi tiết đơn thuốc hoặc xét nghiệm
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm đơn thuốc hoặc xét nghiệm mới
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        tooltip: 'Thêm mới',
      ),
    );
  }
}
