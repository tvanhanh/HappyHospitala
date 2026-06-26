import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/socket_service.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kGrey = Color(0xFF9E9E9E);

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocketListener();
    });
  }

  void _initSocketListener() {
    SocketService.instance.on(SocketEvents.newNotification, (data) {
      if (mounted) {
        final Map<String, dynamic> notification = Map<String, dynamic>.from(data);
        final title = notification['title'] ?? 'Thông báo';
        final body = notification['body'] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1976D2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.off(SocketEvents.newNotification);
    super.dispose();
  }

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/home' ||
        location == '/patient' ||
        location.startsWith('/home?') ||
        location.startsWith('/patient?')) {
      return 0;
    }
    if (location.startsWith('/home/profile') ||
        location.startsWith('/patient/profile-screen')) {
      return 1;
    }
    if (location == '/qa' ||
        location.startsWith('/qa?') ||
        location.startsWith('/home/discussion') ||
        location.startsWith('/patient/chat')) {
      return 2;
    }
    if (location.startsWith('/home/appointments') ||
        location.startsWith('/patient/appointments')) {
      return 3;
    }
    if (location.startsWith('/home/results') ||
        location.startsWith('/patient/medical-records')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _getIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      // ── Wide screen: Rail navigation (tablet/web) ──────────────────────────
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (idx) => _navigate(context, idx),
              useIndicator: true,
              indicatorColor: _kPrimary.withOpacity(0.15),
              selectedIconTheme:
                  const IconThemeData(color: _kPrimary, size: 26),
              unselectedIconTheme: const IconThemeData(color: _kGrey, size: 22),
              selectedLabelTextStyle: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelTextStyle:
                  const TextStyle(color: _kGrey, fontSize: 12),
              minWidth: 76,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations(isRail: true),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_hospital, color: _kPrimary),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // ── Mobile: Modern bottom navigation ──────────────────────────────────────
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Trang chủ',
                  isActive: index == 0,
                  onTap: () => _navigate(context, 0),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Hồ sơ',
                  isActive: index == 1,
                  onTap: () => _navigate(context, 1),
                ),
                _BottomNavItem(
                  icon: Icons.question_answer_outlined,
                  activeIcon: Icons.question_answer_rounded,
                  label: 'Góc tư vấn',
                  isActive: index == 2,
                  onTap: () => _navigate(context, 2),
                ),
                _BottomNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Lịch hẹn',
                  isActive: index == 3,
                  onTap: () => _navigate(context, 3),
                ),
                _BottomNavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Kết quả',
                  isActive: index == 4,
                  onTap: () => _navigate(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final routes = [
      '/home',
      '/home/profile',
      '/qa',
      '/home/appointments',
      '/patient/medical-records',
    ];
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }

  List<NavigationRailDestination> _destinations({bool isRail = false}) => [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Trang chủ'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Hồ sơ'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.question_answer_outlined),
          selectedIcon: Icon(Icons.question_answer_rounded),
          label: Text('Góc tư vấn'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded),
          label: Text('Lịch hẹn'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: Text('Kết quả'),
        ),
      ];
}

/// Custom bottom navigation item with animated selection indicator.
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final routes = [
          '/home',
          '/home/profile',
          '/qa',
          '/home/appointments',
          '/patient/medical-records',
        ];
        final labels = [
          'Trang chủ',
          'Hồ sơ',
          'Góc tư vấn',
          'Lịch hẹn',
          'Kết quả'
        ];
        final currentLabel = label;
        final i = labels.indexOf(currentLabel);
        if (i >= 0 && i < routes.length) {
          context.go(routes[i]);
        }
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive ? _kPrimary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _kPrimary : _kGrey,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? _kPrimary : _kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
