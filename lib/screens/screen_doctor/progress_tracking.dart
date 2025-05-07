import 'package:flutter/material.dart';

class ProgressTrackingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiến Trình Điều Trị'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Tiến Trình Điều Trị Bệnh Nhân',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.track_changes, color: Colors.teal),
              title: Text('Bệnh Nhân A'),
              subtitle: Text('Tiến trình: 70%'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to detailed progress tracking
              },
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.track_changes, color: Colors.teal),
              title: Text('Bệnh Nhân B'),
              subtitle: Text('Tiến trình: 45%'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to detailed progress tracking
              },
            ),
          ],
        ),
      ),
    );
  }
}
