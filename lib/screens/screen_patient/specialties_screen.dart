import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/specialty_provider.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);

class SpecialtiesScreen extends ConsumerWidget {
  const SpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSpecialties = ref.watch(specialtyProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Chọn Chuyên Khoa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner HD / AI Triage CTA
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bạn chưa biết khám ở đâu?',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy để Trợ lý AI phân tích triệu chứng và gợi ý chuyên khoa phù hợp nhất cho bạn.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/patient/ai-triage'),
                        icon: const Icon(Icons.psychology_rounded, size: 18),
                        label: const Text('Hỏi AI Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _kPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                  ),
                ),
                if (isDesktop) const SizedBox(width: 24),
                if (isDesktop)
                  const Icon(Icons.smart_toy_rounded, size: 80, color: Colors.white24)
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Danh sách chuyên khoa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextPrimary)),
            ),
          ),

          Expanded(
            child: asyncSpecialties.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (specialties) {
                if (specialties.isEmpty) {
                  return const Center(child: Text('Chưa có chuyên khoa nào.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: specialties.length,
                  itemBuilder: (context, index) {
                    final spec = specialties[index];
                    return GestureDetector(
                      onTap: () {
                        context.push('/patient/book-appointment/doctors/${spec.id}');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: spec.imageUrl.isNotEmpty && spec.imageUrl.startsWith('http')
                                  ? Image.network(spec.imageUrl, width: 36, height: 36, fit: BoxFit.contain)
                                  : const Icon(Icons.medical_services_rounded, size: 36, color: _kPrimary),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                spec.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kTextPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

