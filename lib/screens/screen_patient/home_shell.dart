/// Patient Home Shell — bottom navigation wrapper.
///
/// [Core-4] UI/UX Polish:
/// - Modern bottom navigation bar with Primary Blue selected color
/// - Smooth page transitions via GoRouter
/// - Responsive: on wide screens (tablet/web), navigation moves to sidebar
/// - [Core-3] Added 'Chat' tab to navigate to ChatScreen
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kGrey = Color(0xFF9E9E9E);

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

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
    if (location.startsWith('/home/discussion') ||
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
            Expanded(child: child),
          ],
        ),
      );
    }

    // ── Mobile: Modern bottom navigation ──────────────────────────────────────
    return Scaffold(
      body: child,
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
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Thảo luận',
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
      '/home/discussion',
      '/home/appointments',
      '/home/results',
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
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: Text('Thảo luận'),
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
        // Navigate using GoRouter
        final routes = [
          '/home',
          '/home/profile',
          '/home/discussion',
          '/home/appointments',
          '/home/results',
        ];
        final labels = [
          'Trang chủ',
          'Hồ sơ',
          'Thảo luận',
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
