import 'package:flutter/material.dart';
import '../../widgets/role_based_nav_drawer.dart';

class DoctorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor ')),
      drawer: RoleBasedNavDrawer(role: 'doctor'),
      body: Center(child: Text('Welcome Doctor')),
    );
  }
}
