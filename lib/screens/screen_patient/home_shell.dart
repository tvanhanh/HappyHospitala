import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/home/profile')) return 1;
    if (location.startsWith('/home/discussion')) return 2;
    if (location.startsWith('/home/appointments')) return 3;
    if (location.startsWith('/home/results')) return 4;
    if (location.startsWith('/patient/medical-records')) return 5;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _getIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/home/profile');
              break;
            case 2:
              context.go('/home/discussion');
              break;
            case 3:
              context.go('/home/appointments');
              break;
            case 4:
              context.go('/home/results');
              break;
            case 5:
              context.go('/patient/medical-records');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Thông tin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Thảo luận',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Kết quả',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Bệnh án',
          ),
        ],
      ),
    );
  }
}
