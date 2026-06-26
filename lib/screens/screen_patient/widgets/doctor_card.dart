import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/doctor.dart';
import '../../../providers/auth_provider.dart';

class DoctorCard extends ConsumerWidget {
  final Doctor doctor;
  final bool isMobile;
  final bool isWide;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.isMobile,
    required this.isWide,
  });

  static const Color _kPrimary = Color(0xFF2563EB);
  static const Color _kPrimaryDark = Color(0xFF1E3A8A);
  static const Color _kTextPrimary = Color(0xFF0F172A);
  static const Color _kTextSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = !ref.watch(authProvider).isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;

    // Card configuration matching design tokens
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

    return GestureDetector(
      onTap: () {
        if (isGuest) {
          context.push('/auth/login');
        } else {
          context.push('/doctor-detail/${doctor.id}');
        }
      },
      child: Container(
        width: isWide ? null : cardWidth,
        margin: isWide
            ? const EdgeInsets.only(bottom: 8)
            : EdgeInsets.only(right: rightMargin, bottom: 8, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: _kPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            SizedBox(height: topPadding),
            Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'doc_${doctor.id}',
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.15),
                          width: isMobile ? 2 : 3),
                      boxShadow: [
                        BoxShadow(
                            color: _kPrimary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                      image: DecorationImage(
                        image: NetworkImage(doctor.avatar.isNotEmpty
                            ? doctor.avatar
                            : 'https://cdn-icons-png.flaticon.com/512/3774/3774299.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '${doctor.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                doctor.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: nameFontSize,
                    color: _kTextPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doctor.specialty.isNotEmpty ? doctor.specialty : 'Đa khoa',
              style: TextStyle(
                  color: _kPrimary,
                  fontSize: specFontSize,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing),
            Divider(height: 1, indent: isMobile ? 12 : 16, endIndent: isMobile ? 12 : 16),
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.work_history_rounded, size: iconSize, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doctor.experience.isNotEmpty && doctor.experience != '0'
                              ? '${doctor.experience} năm kinh nghiệm'
                              : 'Bác sĩ chuyên khoa',
                          style: TextStyle(
                            fontSize: detailFontSize,
                            color: _kTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded, size: iconSize, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doctor.price.isNotEmpty && doctor.price != '0'
                              ? '${doctor.price}đ / lần'
                              : 'Giá liên hệ',
                          style: TextStyle(
                            fontSize: detailFontSize,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kPrimaryDark, _kPrimary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isMobile ? 18 : 22),
                    bottomRight: Radius.circular(isMobile ? 18 : 22)),
              ),
              child: Center(
                child: Text('Đặt Lịch & Chi Tiết',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
