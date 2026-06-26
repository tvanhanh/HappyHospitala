import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:ui' show ImageFilter;

import '../../providers/home_provider.dart';
import '../../providers/specialty_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clinic_service_provider.dart';
import 'customer_messenger_screen.dart';
import 'widgets/specialty_chip.dart';
import 'widgets/service_card.dart';
import 'widgets/doctor_card.dart';
// ── Design Tokens 2026 ─────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF2563EB);
const Color _kPrimaryDark = Color(0xFF1E3A8A);
const Color _kAccent = Color(0xFF38BDF8);
const Color _kBackground = Color(0xFFF8FAFC);

const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color kSecondaryColor = Color(0xFF2563EB);
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _sliderIndex = 0;
  bool _isScrolled = false;
  String? _selectedSpecialtyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  bool get _isGuest => !ref.watch(authProvider).isAuthenticated;
  String get _userName => ref.watch(authProvider).name ?? '';
  String get _userRole => ref.watch(authProvider).role.value;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebWide = screenWidth >= 960;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.15),
            builder: (BuildContext context) {
              return const CustomerMessengerScreen();
            },
          );
        },
        backgroundColor: kSecondaryColor,
        elevation: 4,
        icon: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
        label: const Text(
          "Hỗ trợ khách hàng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
        ),
      ),
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildHeroSection()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (!_isGuest) SliverToBoxAdapter(child: _buildQuickActions()),
            // Web: Stats bar
            if (isWebWide) 
           //SliverToBoxAdapter(child: _buildWebStatsBar()),
            SliverToBoxAdapter(child: _buildSpecialties()),
            SliverToBoxAdapter(child: _buildFeaturedDoctors()),
            SliverToBoxAdapter(child: _buildFeaturedServices()),
            SliverToBoxAdapter(child: _buildClinicInfo()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── WEB STATS BAR ────────────────────────────────────────────────────────

  // ─── SLIVER APP BAR ───────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 0,
      toolbarHeight: 70,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isScrolled ? Colors.white : Colors.transparent,
          boxShadow: _isScrolled
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_hospital, color: _kPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isGuest
                                ? 'Happy Hospital'
                                : 'Chào, ${_userName.split(' ').last}',
                            style: const TextStyle(
                              color: _kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Sức khỏe là vàng ✨',
                            style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isGuest)
                      ElevatedButton(
                        onPressed: () => context.push('/auth/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Đăng nhập',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      )
                    else
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'profile') {
                            context.push('/patient/profile-screen');
                          } else if (value == 'logout') {
                            // Confirm logout
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text("Xác nhận đăng xuất"),
                                content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogCtx);
                                      await ref.read(authProvider.notifier).logout();
                                      if (context.mounted) {
                                        context.go('/auth/login');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                    child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, color: _kTextSecondary),
                                SizedBox(width: 12),
                                Text('Hồ sơ sức khỏe', style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                                SizedBox(width: 12),
                                Text('Đăng xuất', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.3), width: 2),
                            image: DecorationImage(
                              image: NetworkImage(ref.watch(authProvider).avatarUrl != null &&
                                      ref.watch(authProvider).avatarUrl!.isNotEmpty
                                  ? ref.watch(authProvider).avatarUrl!
                                  : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HERO SLIDER SECTION ──────────────────────────────────────────────────
  Widget _buildHeroSection() {
    final asyncSliders = ref.watch(homeSliderProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth >= 800;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: asyncSliders.when(
          loading: () => _buildDefaultSlider(),
          error: (_, __) => _buildDefaultSlider(),
          data: (sliders) {
            if (sliders.isEmpty) return _buildDefaultSlider();

            return Column(
              children: [
                const SizedBox(height: 8),
                Stack(
                  children: [
                    CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: sliders.length,
                      itemBuilder: (context, index, realIndex) {
                        final slider = sliders[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // Background Image (100% crisp and clear)
                                Image.network(
                                  slider.imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_kPrimaryDark, _kPrimary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.white24),
                                    ),
                                  ),
                                ),
                                // Clean Left-to-Right Linear Gradient Overlay (fades completely by 60% width)
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          const Color(0xFF0F172A).withValues(alpha: 0.85),
                                          const Color(0xFF0F172A).withValues(alpha: 0.65),
                                          const Color(0xFF0F172A).withValues(alpha: 0.15),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.35, 0.65, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Content Overlay (aligned to left)
                                Positioned(
                                  left: isMobile ? 24 : 64,
                                  top: isMobile ? 16 : 24,
                                  bottom: isMobile ? 16 : 24,
                                  right: isMobile ? 24 : 120,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Small Premium Tag
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 6 : 8,
                                            vertical: isMobile ? 2 : 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.18),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "NỔI BẬT",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontSize: isMobile ? 7.5 : 8.0,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 6 : 12),
                                      // Title
                                      Text(
                                        slider.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 16.0 : 22.0,
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (slider.subtitle.isNotEmpty) ...[
                                        SizedBox(height: isMobile ? 4 : 6),
                                        // Subtitle
                                        Text(
                                          slider.subtitle,
                                          maxLines: isMobile ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: isMobile ? 11.0 : 13.0,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: isMobile ? 8 : 14),
                                      // Primary CTA Button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (_isGuest) {
                                            context.push('/auth/login');
                                          } else {
                                            context.push('/patient/specialties_screen');
                                          }
                                        },
                                        icon: Icon(Icons.calendar_month_rounded, size: isMobile ? 12 : 14),
                                        label: Text(
                                          'Đặt lịch ngay',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 10.5 : 12.0,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: _kPrimary,
                                          elevation: 3,
                                          shadowColor: Colors.black.withValues(alpha: 0.15),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 12 : 18,
                                              vertical: isMobile ? 8 : 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: isWide ? 380 : 220,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        enlargeCenterPage: true,
                        viewportFraction: 0.95,
                        onPageChanged: (i, _) => setState(() => _sliderIndex = i),
                      ),
                    ),
                    // Visible Navigation Arrow: Left (Blurred & Translucent on Web)
                    if (!isMobile)
                      Positioned(
                        left: 24,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _carouselController.previousPage(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Visible Navigation Arrow: Right (Blurred & Translucent on Web)
                    if (!isMobile)
                      Positioned(
                        right: 24,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _carouselController.nextPage(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sliders.asMap().entries.map((e) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _sliderIndex == e.key ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _sliderIndex == e.key
                            ? _kPrimary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultSlider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth >= 800;
    final slides = [
      {
        'title': 'Chăm Sóc Sức Khỏe Toàn Diện',
        'sub': 'Đội ngũ bác sĩ chuyên nghiệp, tận tâm',
        'imageUrl': 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
        'tag': 'TẬN TÂM',
        'icon': Icons.health_and_safety,
        'colors': [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
      },
      {
        'title': 'Đặt Lịch Khám Dễ Dàng',
        'sub': 'Chỉ vài bước đơn giản, tiết kiệm thời gian',
        'imageUrl': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=800&q=80',
        'tag': 'NHANH CHÓNG',
        'icon': Icons.calendar_month,
        'colors': [const Color(0xFF047857), const Color(0xFF10B981)],
      },
      {
        'title': 'Hỗ Trợ AI Thông Minh',
        'sub': 'Phân tích triệu chứng, tư vấn 24/7',
        'imageUrl': 'https://images.unsplash.com/photo-1526256262350-7da7584cf5eb?auto=format&fit=crop&w=800&q=80',
        'tag': 'CÔNG NGHỆ',
        'icon': Icons.psychology,
        'colors': [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Stack(
              children: [
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: slides.length,
                  itemBuilder: (context, index, _) {
                    final slide = slides[index];
                    final colors = slide['colors'] as List<Color>;
                    final imageUrl = slide['imageUrl'] as String;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: colors[0].withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Background Image
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  slide['icon'] as IconData,
                                  size: 120,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            // Clean Left-to-Right Linear Gradient Overlay (fades completely by 60% width)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      const Color(0xFF0F172A).withValues(alpha: 0.85),
                                      const Color(0xFF0F172A).withValues(alpha: 0.65),
                                      const Color(0xFF0F172A).withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.35, 0.65, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Content Overlay (aligned to left)
                            Positioned(
                              left: isMobile ? 24 : 64,
                              top: isMobile ? 16 : 24,
                              bottom: isMobile ? 16 : 24,
                              right: isMobile ? 24 : 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Small Premium Tag
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 6 : 8,
                                        vertical: isMobile ? 2 : 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      slide['tag'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: isMobile ? 7.5 : 8.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 6 : 12),
                                  // Title
                                  Text(
                                    slide['title'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 16.0 : 22.0,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  // Subtitle
                                  Text(
                                    slide['sub'] as String,
                                    maxLines: isMobile ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: isMobile ? 11.0 : 13.0,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 14),
                                  // Primary CTA Button
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (_isGuest) {
                                        context.push('/auth/login');
                                      } else {
                                        context.push('/patient/specialties_screen');
                                      }
                                    },
                                    icon: Icon(Icons.calendar_month_rounded, size: isMobile ? 12 : 14),
                                    label: Text(
                                      'Đặt lịch ngay',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 10.5 : 12.0,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: colors[0],
                                      elevation: 3,
                                      shadowColor: Colors.black.withValues(alpha: 0.15),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 12 : 18,
                                          vertical: isMobile ? 8 : 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: isWide ? 380 : 220,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    enlargeCenterPage: true,
                    viewportFraction: 0.95,
                    onPageChanged: (i, _) => setState(() => _sliderIndex = i),
                  ),
                ),
                // Visible Navigation Arrow: Left (Blurred & Translucent on Web)
                if (!isMobile)
                  Positioned(
                    left: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _carouselController.previousPage(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Visible Navigation Arrow: Right (Blurred & Translucent on Web)
                if (!isMobile)
                  Positioned(
                    right: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _carouselController.nextPage(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _sliderIndex == i ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _sliderIndex == i
                        ? _kPrimary
                        : Colors.grey.withValues(alpha: 0.35),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bác sĩ, chuyên khoa...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kPrimary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.close_rounded, color: _kTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ───────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Đặt khám',
        'color': _kPrimary,
        'route': '/patient/specialties_screen',
        'bg': const Color(0xFFEFF6FF)
      },
      {
        'icon': Icons.history_rounded,
        'label': 'Lịch hẹn',
        'color': const Color(0xFF059669),
        'route': '/patient/appointments',
        'bg': const Color(0xFFECFDF5)
      },
      {
        'icon': Icons.contact_support_rounded,
        'label': 'Góc Tư vấn',
        'color': const Color(0xFF7C3AED),
        'route': '/qa',
        'bg': const Color(0xFFF5F3FF)
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: actions.map((a) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.push(a['route'] as String),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: a['bg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: (a['color'] as Color).withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(a['icon'] as IconData,
                            color: a['color'] as Color, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          a['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: a['color'] as Color),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── SPECIALTIES ─────────────────────────────────────────────────────────
  Widget _buildSpecialties() {
    final asyncSpecialties = ref.watch(specialtyProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chuyên Khoa',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kTextPrimary)),
                  TextButton(
                    onPressed: () => context.push('/patient/specialties_screen'),
                    style: TextButton.styleFrom(
                        foregroundColor: _kPrimary, padding: EdgeInsets.zero),
                    child: const Row(
                      children: [
                        Text('Xem tất cả',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              asyncSpecialties.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator())),
                error: (_, __) => _buildStaticSpecialties(isWide),
                data: (specialties) {
                  if (specialties.isEmpty) return _buildStaticSpecialties(isWide);

                  // Filter by search query
                  final filtered = _searchQuery.isEmpty
                      ? specialties
                      : specialties
                          .where((s) => s.name.toLowerCase().contains(_searchQuery))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Không tìm thấy chuyên khoa "$_searchQuery"',
                            style: const TextStyle(color: _kTextSecondary)),
                      ),
                    );
                  }

                  final displayList =
                      filtered.length > 12 ? filtered.sublist(0, 12) : filtered;

                  if (isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth >= 1400 ? 8 : (screenWidth >= 960 ? 6 : 4),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: displayList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return SpecialtyChip(
                            name: 'Tất cả',
                            imageUrl: '',
                            isSelected: _selectedSpecialtyId == null,
                            onTap: () =>
                                setState(() => _selectedSpecialtyId = null),
                            isAll: true,
                            isWide: true,
                          );
                        }
                        final spec = displayList[index - 1];
                        return SpecialtyChip(
                          name: spec.name,
                          imageUrl: spec.imageUrl,
                          isSelected: _selectedSpecialtyId == spec.id,
                          onTap: () =>
                              setState(() => _selectedSpecialtyId = spec.id),
                          isWide: true,
                        );
                      },
                    );
                  }

                  return SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return SpecialtyChip(
                            name: 'Tất cả',
                            imageUrl: '',
                            isSelected: _selectedSpecialtyId == null,
                            onTap: () =>
                                setState(() => _selectedSpecialtyId = null),
                            isAll: true,
                          );
                        }
                        final spec = displayList[index - 1];
                        return SpecialtyChip(
                          name: spec.name,
                          imageUrl: spec.imageUrl,
                          isSelected: _selectedSpecialtyId == spec.id,
                          onTap: () =>
                              setState(() => _selectedSpecialtyId = spec.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticSpecialties(bool isWide) {
    final statics = [
      {'name': 'Nội khoa', 'icon': '🫀'},
      {'name': 'Ngoại khoa', 'icon': '🔬'},
      {'name': 'Nhi khoa', 'icon': '👶'},
      {'name': 'Da liễu', 'icon': '🧴'},
      {'name': 'Tim mạch', 'icon': '❤️'},
      {'name': 'Thần kinh', 'icon': '🧠'},
    ];
    if (isWide) {
      final screenWidth = MediaQuery.of(context).size.width;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth >= 1400 ? 8 : (screenWidth >= 960 ? 6 : 4),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: statics.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return SpecialtyChip(
                name: 'Tất cả',
                imageUrl: '',
                isSelected: _selectedSpecialtyId == null,
                onTap: () => setState(() => _selectedSpecialtyId = null),
                isAll: true,
                isWide: true);
          }
          final s = statics[i - 1];
          return SpecialtyChip(
              name: s['name']!, imageUrl: '', isSelected: false, onTap: () {}, isWide: true);
        },
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statics.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return SpecialtyChip(
                name: 'Tất cả',
                imageUrl: '',
                isSelected: _selectedSpecialtyId == null,
                onTap: () => setState(() => _selectedSpecialtyId = null),
                isAll: true);
          }
          final s = statics[i - 1];
          return SpecialtyChip(
              name: s['name']!, imageUrl: '', isSelected: false, onTap: () {});
        },
      ),
    );
  }



  // ─── FEATURED SERVICES ───────────────────────────────────────────────────
  Widget _buildFeaturedServices() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final asyncServices = ref.watch(clinicServiceProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 6),
                  Text('Dịch Vụ Nổi Bật',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kTextPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              asyncServices.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Không thể tải danh sách dịch vụ: $err',
                      style: const TextStyle(color: _kTextSecondary),
                    ),
                  ),
                ),
                data: (servicesList) {
                  if (servicesList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Không có dịch vụ nào khả dụng.',
                          style: TextStyle(color: _kTextSecondary),
                        ),
                      ),
                    );
                  }

                  return isWide
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth >= 1400 ? 4 : (screenWidth >= 960 ? 3 : 2),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 160,
                          ),
                          itemCount: servicesList.length,
                          itemBuilder: (context, i) {
                            return ServiceCard(
                              service: servicesList[i],
                              index: i,
                              isWide: true,
                            );
                          },
                        )
                      : SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: servicesList.length,
                            itemBuilder: (context, i) {
                              return ServiceCard(
                                service: servicesList[i],
                                index: i,
                                isWide: false,
                              );
                            },
                          ),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FEATURED DOCTORS ────────────────────────────────────────────────────
  Widget _buildFeaturedDoctors() {
    final asyncDoctors = ref.watch(doctorsBySpecialtyProvider(_selectedSpecialtyId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedSpecialtyId == null
                        ? 'Bác Sĩ Nổi Bật'
                        : 'Bác Sĩ Chuyên Khoa',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kTextPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.push('/patient/doctor_list'),
                    style: TextButton.styleFrom(
                        foregroundColor: _kPrimary, padding: EdgeInsets.zero),
                    child: const Row(
                      children: [
                        Text('Xem tất cả',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              asyncDoctors.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator())),
                error: (e, _) => Center(
                    child: Text('Không thể tải dữ liệu: $e',
                        style: const TextStyle(color: _kTextSecondary))),
                data: (doctors) {
                  final isMobile = screenWidth < 600;

                  // Card configuration
                  final double rightMargin = isMobile ? 10.0 : 14.0;
                  final double cardWidth = isMobile ? ((screenWidth - 40 - rightMargin) / 2).clamp(130.0, 210.0) : 210.0;
                  final double cardHeight = isMobile ? 260.0 : 310.0;
                  final double avatarSize = isMobile ? 64.0 : 84.0;
                  final double nameFontSize = isMobile ? 13.0 : 15.0;
                  final double specFontSize = isMobile ? 10.0 : 11.0;
                  final double detailFontSize = isMobile ? 9.5 : 11.0;
                  final double iconSize = isMobile ? 12.0 : 14.0;
                  final double topPadding = isMobile ? 12.0 : 16.0;
                  final double spacing = isMobile ? 8.0 : 12.0;

                  // Filter by search query
                  final searchFiltered = _searchQuery.isEmpty
                      ? doctors
                      : doctors
                          .where((d) =>
                              d.name.toLowerCase().contains(_searchQuery) ||
                              d.specialty.toLowerCase().contains(_searchQuery))
                          .toList();

                  if (searchFiltered.isEmpty) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                              ? 'Không tìm thấy bác sĩ "$_searchQuery"'
                              : 'Không có bác sĩ nào thuộc chuyên khoa này',
                            style: const TextStyle(
                                color: _kTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth >= 1400 ? 5 : (screenWidth >= 960 ? 4 : 3),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: cardHeight + 8,
                      ),
                      itemCount: searchFiltered.length,
                      itemBuilder: (context, index) {
                        return DoctorCard(
                          doctor: searchFiltered[index],
                          isMobile: isMobile,
                          isWide: true,
                        );
                      },
                    );
                  }

                  return SizedBox(
                    height: cardHeight + 8,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: searchFiltered.length,
                      itemBuilder: (context, index) {
                        return DoctorCard(
                          doctor: searchFiltered[index],
                          isMobile: isMobile,
                          isWide: false,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



  // ─── CLINIC INFO FOOTER ──────────────────────────────────────────────────
  Widget _buildClinicInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimaryDark, Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: _kPrimaryDark.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: isDesktop
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Info & Details
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14)),
                                    child: const Icon(Icons.local_hospital_rounded,
                                        color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Happy Clinic',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      Text('Chăm sóc sức khỏe toàn diện',
                                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            // Info rows
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _infoRow(Icons.location_on_rounded, 'Địa chỉ',
                                      '317 Trần Đại Nghĩa, Đà Nẵng'),
                                  const SizedBox(height: 12),
                                  _infoRow(Icons.phone_rounded, 'Hotline', '0236 3841 111'),
                                  const SizedBox(height: 12),
                                  _infoRow(Icons.schedule_rounded, 'Giờ làm việc',
                                      'Thứ 2 - Thứ 7: 7h00 - 17h30'),
                                  const SizedBox(height: 12),
                                  _infoRow(
                                      Icons.email_rounded, 'Email', 'contact@happyhospital.vn'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
                      // Column 2: Action buttons & Copyright
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'ĐĂNG KÝ HẸN GIỜ TRỰC TUYẾN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Liên hệ nhanh qua Hotline hoặc đặt lịch khám online với đội ngũ bác sĩ chuyên khoa của chúng tôi chỉ trong 2 phút.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.phone_rounded, size: 16),
                                      label: const Text('Gọi ngay',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white54),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.push('/patient/doctor_list'),
                                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                      label: const Text('Đặt lịch',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: _kPrimary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                '© 2026 Happy Clinic. All rights reserved.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.local_hospital_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Happy Clinic',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text('Chăm sóc sức khỏe toàn diện',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                    // Info rows
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow(Icons.location_on_rounded, 'Địa chỉ',
                              '317 Trần Đại Nghĩa, Đà Nẵng'),
                          const SizedBox(height: 12),
                          _infoRow(Icons.phone_rounded, 'Hotline', '0236 3841 111'),
                          const SizedBox(height: 12),
                          _infoRow(Icons.schedule_rounded, 'Giờ làm việc',
                              'Thứ 2 - Thứ 7: 7h00 - 17h30'),
                          const SizedBox(height: 12),
                          _infoRow(
                              Icons.email_rounded, 'Email', 'contact@happyhospital.vn'),
                        ],
                      ),
                    ),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: const Text('Gọi ngay',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/patient/doctor_list'),
                              icon: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: const Text('Đặt lịch',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _kPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Copyright
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24)),
                      ),
                      child: const Text(
                        '© 2026 Happy Clinic. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _kAccent, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Decorative background painter for web sidebar ─────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 1.8;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
