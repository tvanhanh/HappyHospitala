import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ThankYouScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận đặt lịch")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Lịch của bạn đã được hủy. Cảm ơn bạn! 🎉",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/home'); // Quay lại trang chủ
              },
              child: const Text("Về Trang Chủ"),
            ),
          ],
        ),
      ),
    );
  }
}
