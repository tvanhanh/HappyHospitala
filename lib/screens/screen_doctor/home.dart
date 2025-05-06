import 'package:flutter/material.dart';
import '../../widgets/role_based_nav_drawer.dart';
import './chatAI_screen.dart'; // Đường dẫn đến ChatScreen

class DoctorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor')),
      drawer: RoleBasedNavDrawer(role: 'doctor'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome Doctor'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text("Trò chuyện với AI"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
