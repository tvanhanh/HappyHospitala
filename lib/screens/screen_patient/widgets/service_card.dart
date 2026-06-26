import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/clinic_service.dart';

class ServiceCard extends StatelessWidget {
  final ClinicService service;
  final int index;
  final bool isWide;

  const ServiceCard({
    super.key,
    required this.service,
    required this.index,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    // Style configurations based on index
    final styleIndex = index % 6;
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFFF59E0B),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFFEF4444),
      const Color(0xFF2563EB),
    ];
    final bgs = [
      const Color(0xFFF5F3FF),
      const Color(0xFFFFFBEB),
      const Color(0xFFECFEFF),
      const Color(0xFFECFDF5),
      const Color(0xFFFEF2F2),
      const Color(0xFFEFF6FF),
    ];
    final icons = [
      Icons.psychology_rounded,
      Icons.child_care_rounded,
      Icons.visibility_rounded,
      Icons.science_rounded,
      Icons.favorite_rounded,
      Icons.medical_services_rounded,
    ];

    final color = colors[styleIndex];
    final bg = bgs[styleIndex];
    final icon = icons[styleIndex];

    final route = _getServiceRoute(service.name);

    return GestureDetector(
      onTap: () {
        context.push(route);
      },
      child: Container(
        width: isWide ? null : 160,
        margin: isWide ? EdgeInsets.zero : const EdgeInsets.only(right: 12, bottom: 4, top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              service.description.isNotEmpty ? service.description : 'Dịch vụ y tế chuyên nghiệp của Happy Clinic',
              style: const TextStyle(
                  fontSize: 9, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              service.price > 0 ? '${_formatPrice(service.price)}đ' : 'Miễn phí',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceRoute(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ai') || lower.contains('tư vấn') || lower.contains('triage') || lower.contains('trí tuệ')) {
      return '/patient/ai-triage';
    }

    String? specialty;
    if (lower.contains('nội') || lower.contains('tiết')) {
      specialty = 'Nội tiết';
    } else if (lower.contains('da liễu')) {
      specialty = 'Da liễu';
    } else if (lower.contains('nhi khoa') || lower.contains('nhi')) {
      specialty = 'Nhi khoa';
    } else if (lower.contains('tim mạch') || lower.contains('tim')) {
      specialty = 'Tim mạch';
    } else if (lower.contains('thần kinh')) {
      specialty = 'Thần kinh';
    } else if (lower.contains('nha khoa') || lower.contains('răng')) {
      specialty = 'Nha khoa';
    }

    if (specialty != null) {
      // Encode query component to ensure safe URLs
      return '/patient/doctor_list?specialty=${Uri.encodeComponent(specialty)}';
    }
    return '/patient/doctor_list';
  }

  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
