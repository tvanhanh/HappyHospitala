/// A reusable responsive scaffold widget for Staff-facing dashboards.
///
/// Implements the cross-platform layout strategy:
/// - **Web/Desktop** (width ≥ 800px): Persistent left sidebar + content area.
///   No AppBar needed — navigation is always visible.
/// - **Mobile** (width < 800px): Standard AppBar + Drawer + optional BottomNavigationBar.
///
/// This widget is used as the base for [CashierDashboard] and [PharmacyDashboard].
/// It can be reused for any future staff-type role screen.
///
/// Usage:
/// ```dart
/// RoleResponsiveScaffold(
///   roleTitle: 'Thu Ngân',
///   roleIcon: Icons.payments_rounded,
///   accentColor: Color(0xFF1565C0),
///   menuItems: [...],
///   pages: [...],
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Width breakpoint in logical pixels to switch between sidebar and drawer layout.
const double _kSidebarBreakpoint = 800.0;

/// Defines a single navigation item in the role dashboard sidebar/drawer.
class RoleMenuItem {
  /// The material icon displayed next to the label.
  final IconData icon;

  /// The Vietnamese label displayed in the sidebar/drawer.
  final String label;

  /// Creates a [RoleMenuItem].
  const RoleMenuItem({required this.icon, required this.label});
}

/// A responsive scaffold for role-based staff dashboards.
///
/// Adapts to screen width: sidebar on Web/Desktop, Drawer on Mobile.
class RoleResponsiveScaffold extends StatefulWidget {
  /// The role name shown in the header (e.g., 'Thu Ngân').
  final String roleTitle;

  /// Icon representing this role in the header.
  final IconData roleIcon;

  /// Primary accent color for the sidebar/header background gradient.
  final Color accentColor;

  /// Navigation menu items for this role's dashboard.
  final List<RoleMenuItem> menuItems;

  /// Pages (content widgets) corresponding to each [menuItems] index.
  final List<Widget> pages;

  /// Creates a [RoleResponsiveScaffold].
  const RoleResponsiveScaffold({
    super.key,
    required this.roleTitle,
    required this.roleIcon,
    required this.accentColor,
    required this.menuItems,
    required this.pages,
  });

  @override
  State<RoleResponsiveScaffold> createState() => _RoleResponsiveScaffoldState();
}

class _RoleResponsiveScaffoldState extends State<RoleResponsiveScaffold> {
  int _selectedIndex = 0;

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    // Close mobile drawer if open
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/auth/login');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kSidebarBreakpoint;

        return isWide
            ? _buildWebLayout(context)
            : _buildMobileLayout(context);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WEB / DESKTOP LAYOUT — Persistent Left Sidebar
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // ── Left Sidebar (always visible on web) ─────────────────────────
          _buildSidebar(),

          // ── Main Content Area ─────────────────────────────────────────────
          Expanded(
            child: widget.pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  /// The persistent left sidebar shown on Web/Desktop.
  Widget _buildSidebar() {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor,
            widget.accentColor.withBlue(
              (widget.accentColor.blue + 40).clamp(0, 255),
            ),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: widget.menuItems.length,
              itemBuilder: (ctx, i) => _buildSidebarItem(i),
            ),
          ),

          // Logout footer
          _buildSidebarLogout(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.roleIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roleTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'HappyClinic',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index) {
    final item = widget.menuItems[index];
    final isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        // Left border highlight for selected item
        shape: isSelected
            ? const RoundedRectangleBorder(
                side: BorderSide(color: Colors.white, width: 2),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              )
            : null,
        onTap: () => _selectPage(index),
      ),
    );
  }

  Widget _buildSidebarLogout() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      child: ListTile(
        leading:
            const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        onTap: _handleLogout,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT — AppBar + Drawer
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.menuItems[_selectedIndex].label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withBlue(
                (widget.accentColor.blue + 40).clamp(0, 255),
              )],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildMobileDrawerHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.menuItems.length,
                itemBuilder: (ctx, i) => _buildDrawerItem(i),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: widget.pages[_selectedIndex],
    );
  }

  Widget _buildMobileDrawerHeader() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.accentColor, widget.accentColor.withBlue(
            (widget.accentColor.blue + 40).clamp(0, 255),
          )],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.roleIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.roleTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'HappyClinic System',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index) {
    final item = widget.menuItems[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? widget.accentColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(
          item.icon,
          color:
              isSelected ? widget.accentColor : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected
                ? widget.accentColor
                : Colors.grey.shade800,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => _selectPage(index),
      ),
    );
  }
}
