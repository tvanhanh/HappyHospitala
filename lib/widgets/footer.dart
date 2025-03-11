import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blueGrey,
      child: Column(
        children: [
          Text('© 2025 - Hệ thống đặt lịch khám bệnh',
              style: TextStyle(color: Colors.white)),
          Text('Liên hệ: support@example.com | Hotline: 0123 456 789',
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
