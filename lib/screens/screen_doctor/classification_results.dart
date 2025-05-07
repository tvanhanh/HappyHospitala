import 'package:flutter/material.dart';

class ClassificationResultsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết Quả Phân Loại'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Kết Quả Phân Loại Bệnh Nhân',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.bar_chart, color: Colors.teal),
                title: Text('Bệnh Nhân 1'),
                subtitle: Text('Loại: Nguy hiểm'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to detailed classification result
                },
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.bar_chart, color: Colors.teal),
                title: Text('Bệnh Nhân 2'),
                subtitle: Text('Loại: Bình thường'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to detailed classification result
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
