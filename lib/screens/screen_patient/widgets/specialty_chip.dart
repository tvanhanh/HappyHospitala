import 'package:flutter/material.dart';

class SpecialtyChip extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAll;
  final bool isWide;

  const SpecialtyChip({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
    this.isAll = false,
    this.isWide = false,
  });

  static const Color _kPrimary = Color(0xFF2563EB);
  static const Color _kPrimaryDark = Color(0xFF1E3A8A);
  static const Color _kTextPrimary = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 84,
        margin: isWide ? EdgeInsets.zero : const EdgeInsets.only(right: 10, bottom: 4, top: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_kPrimaryDark, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _kPrimary.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: isAll
                  ? Icon(Icons.grid_view_rounded,
                      color: isSelected ? Colors.white : _kPrimary, size: 22)
                  : (imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? Image.network(imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.medical_services,
                              color: isSelected ? Colors.white : _kPrimary,
                              size: 22))
                      : Icon(Icons.medical_services,
                          color: isSelected ? Colors.white : _kPrimary,
                          size: 22)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : _kTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
