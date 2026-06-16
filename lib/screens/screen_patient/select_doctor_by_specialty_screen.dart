import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/specialty_provider.dart';
import '../../models/specialty.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class SelectDoctorBySpecialtyScreen extends ConsumerWidget {
  final String specialtyId;

  const SelectDoctorBySpecialtyScreen({super.key, required this.specialtyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(doctorsBySpecialtyProvider(specialtyId));
    final asyncSpecialties = ref.watch(specialtyProvider);

    final String specialtyName = asyncSpecialties.when(
      data: (list) {
        final spec = list.firstWhere(
          (s) => s.id == specialtyId,
          orElse: () => const Specialty(id: '', name: 'Chọn Bác Sĩ'),
        );
        return spec.name;
      },
      loading: () => 'Đang tải...',
      error: (_, __) => 'Chọn Bác Sĩ',
    );

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(specialtyName),
        centerTitle: true,
      ),
      body: asyncDoctors.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải bác sĩ: $e')),
        data: (doctors) {
          if (doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: _kTextSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Chuyên khoa này chưa có bác sĩ trực',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return GestureDetector(
                onTap: () => context.push('/doctor-detail/${doctor.id}'),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [_kPrimary.withValues(alpha: 0.05), Colors.blue.withValues(alpha: 0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: doctor.avatar.isNotEmpty && doctor.avatar.startsWith('http')
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      doctor.avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, color: _kPrimary, size: 32),
                                    ),
                                  )
                                : const Icon(Icons.person, color: _kPrimary, size: 32),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialty.isNotEmpty ? doctor.specialty : 'Chuyên khoa',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.experience.isNotEmpty ? '${doctor.experience} năm kinh nghiệm' : 'Kinh nghiệm',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _kTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  doctor.price.isNotEmpty && doctor.price != '0'
                                      ? '${doctor.price}đ/lần'
                                      : 'Liên hệ để biết giá',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: _kPrimary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
