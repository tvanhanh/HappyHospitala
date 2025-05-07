import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống Kê'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Thống Kê Sức Khỏe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.analytics, color: Colors.teal),
                title: Text('Số lượng bệnh nhân'),
                subtitle: Text('Total: 1500'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Show detailed statistics
                },
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.analytics, color: Colors.teal),
                title: Text('Bệnh nhân đang điều trị'),
                subtitle: Text('Total: 200'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Show detailed statistics
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
