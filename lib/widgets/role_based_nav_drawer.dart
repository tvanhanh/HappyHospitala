import 'package:flutter/material.dart';

class RoleBasedNavDrawer extends StatelessWidget {
  final String role;
  const RoleBasedNavDrawer({required this.role});

  @override
  Widget build(BuildContext context) {
    List<Widget> menuItems = [];

    if (role == 'admin') {
      menuItems = [
        ListTile(title: Text('Manage Users'), onTap: () {}),
        ListTile(title: Text('Settings'), onTap: () {}),
      ];
    } else if (role == 'doctor') {
      menuItems = [
        ListTile(title: Text('Appointments'), onTap: () {}),
        ListTile(title: Text('Patients'), onTap: () {}),
      ];
    } else if (role == 'staff') {
      menuItems = [
        ListTile(title: Text('Schedule'), onTap: () {}),
        ListTile(title: Text('Inventory'), onTap: () {}),
      ];
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(child: Text('$role Panel')),
          ...menuItems,
        ],
      ),
    );
  }
}
