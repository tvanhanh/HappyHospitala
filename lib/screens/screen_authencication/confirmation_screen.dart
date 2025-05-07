import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String message; // Thông báo hiển thị
  final IconData icon; // Icon hiển thị

  const ConfirmationScreen(
      {super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 100, color: Colors.green), // Hiển thị icon phù hợp
              const SizedBox(height: 20),
              Text(
                message,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/'); // Điều hướng về trang chủ
                },
                child: const Text('Về Trang Chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
