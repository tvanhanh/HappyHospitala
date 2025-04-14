import 'package:flutter/material.dart';
import '../../widgets/role_based_nav_drawer.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      drawer: RoleBasedNavDrawer(role: 'admin'),
      body: Center(child: Text('Welcome Admin')),
    );
  }
}
