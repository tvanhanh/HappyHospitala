import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/specialty_provider.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kPrimaryDark = Color(0xFF1E3A8A);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class BookAppointmentScreen extends ConsumerWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSpecialties = ref.watch(specialtyProvider);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Chọn Chuyên Khoa'),
        centerTitle: true,
      ),
      body: asyncSpecialties.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải chuyên khoa: $e')),
        data: (specialties) {
          if (specialties.isEmpty) {
            return const Center(child: Text('Chưa có chuyên khoa nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final spec = specialties[index];
              return GestureDetector(
                onTap: () =>
                    context.push('/patient/book-appointment/rooms/${spec.id}'),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _kPrimary.withValues(alpha: 0.05),
                          Colors.blue.withValues(alpha: 0.02)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border:
                          Border.all(color: _kPrimary.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: spec.imageUrl.isNotEmpty &&
                                spec.imageUrl.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  spec.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_hospital,
                                      color: _kPrimary,
                                      size: 28),
                                ),
                              )
                            : const Icon(Icons.local_hospital,
                                color: _kPrimary, size: 28),
                      ),
                      title: Text(
                        spec.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _kTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        spec.description.isNotEmpty
                            ? spec.description
                            : 'Chuyên khoa y tế',
                        style: const TextStyle(
                            color: _kTextSecondary, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: _kPrimary, size: 16),
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
