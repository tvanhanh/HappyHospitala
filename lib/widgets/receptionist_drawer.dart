import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const kPrimaryColor = Color(0xFF0D47A1);
const kTextColor = Color(0xFF333333);
const kSecondaryColor = Color(0xFF1976D2);

class ReceptionistDrawer extends StatelessWidget {
  final String selectedMenu;

  const ReceptionistDrawer({
    super.key,
    required this.selectedMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              "Nguyễn Thị Lan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: const Text("Lễ tân"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: kPrimaryColor,
              ),
            ),
            decoration: const BoxDecoration(
              color: kSecondaryColor,
            ),
          ),

          Expanded(
            child: ListView(
              children: [

                _item(
                  context,
                  Icons.dashboard,
                  "Tổng quan",
                  "/receptionist/dashboard",
                ),

                _item(
                  context,
                  Icons.people,
                  "Quản lý bệnh nhân",
                  "/receptionist/patient-management",
                ),

                _item(
                  context,
                  Icons.calendar_today,
                  "Quản lý lịch hẹn",
                  "/receptionist/appointment-management",
                ),
                _item(
                  context,
                  Icons.access_time,
                  "Danh sách chờ khám",
                  "/receptionist/waiting-list",
                ),
                _item(
                  context,
                  Icons.folder_shared,
                  "Hồ sơ bệnh án",
                  "/receptionist/medical-records",
                ),

                const Divider(),

                _item(
                  context,
                  Icons.notifications,
                  "Thông báo",
                  "/receptionist/notification",
                ),

                _item(
                  context,
                  Icons.settings,
                  "Cài đặt",
                  "/receptionist/settings",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    final selected = selectedMenu == title;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? kSecondaryColor : kPrimaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? kSecondaryColor : kTextColor,
          fontWeight:
              selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: selected
          ? kSecondaryColor.withOpacity(0.08)
          : null,
      onTap: () {
        context.go(route);
      },
    );
  }
}