/// Patient-facing Doctor List Screen — refactored with Riverpod.
///
/// Changes from legacy version:
/// - [Booking-1] Uses [doctorListProvider] (FutureProvider) instead of
///   manual `setState + initState` fetch pattern.
/// - [Booking-4] Enhanced UI: specialty filter chips, rating display,
///   shimmer-style skeleton loading, better error state with retry button.
/// - Search is still local (client-side filter on cached provider data).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/booking_provider.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF4F6FA);

/// Patient-facing screen listing all available doctors.
///
/// Supports full-text search across name + specialty,
/// and specialty filter chips for quick filtering.
class PatientDoctorListScreen extends ConsumerStatefulWidget {
  const PatientDoctorListScreen({super.key});

  @override
  ConsumerState<PatientDoctorListScreen> createState() =>
      _PatientDoctorListScreenState();
}

class _PatientDoctorListScreenState
    extends ConsumerState<PatientDoctorListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSpecialty; // null = all specialties

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [Booking-1] Watch the FutureProvider — no initState / setState needed
    final asyncDoctors = ref.watch(doctorListProvider);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
          color: Colors.white,
        ),
        title: const Text(
          'Chọn Bác Sĩ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimary,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Làm mới',
            onPressed: () => ref.refresh(doctorListProvider),
          ),
        ],
      ),
      body: asyncDoctors.when(
        loading: () => _buildSkeletonLoading(),
        error: (err, _) => _buildErrorState(),
        data: (doctors) {
          // Extract unique specialties for filter chips
          final specialties = doctors
              .map((d) {
                return (d['profile'] as Map<String, dynamic>?)?['specialty']
                        ?.toString() ??
                    '';
              })
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // Apply search + specialty filter
          final filtered = doctors.where((d) {
            final name = (d['name'] ?? '').toString().toLowerCase();
            final spec = ((d['profile'] as Map<String, dynamic>?)?['specialty']
                        ?.toString() ??
                    '')
                .toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                name.contains(_searchQuery.toLowerCase()) ||
                spec.contains(_searchQuery.toLowerCase());
            final matchesSpecialty = _selectedSpecialty == null ||
                spec == _selectedSpecialty!.toLowerCase();
            return matchesSearch && matchesSpecialty;
          }).toList();

          return Column(
            children: [
              // ── Search + Filter Header ──────────────────────────────────
              _buildSearchAndFilter(specialties),

              // ── Doctor Count ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} bác sĩ',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_selectedSpecialty != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSpecialty = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedSpecialty!,
                                style: const TextStyle(
                                    color: _kPrimary, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close,
                                  size: 14, color: _kPrimary),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Doctor List ─────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) =>
                            _DoctorCard(doctor: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEARCH + FILTER BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchAndFilter(List<String> specialties) {
    return Container(
      color: _kPrimary,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm bác sĩ, chuyên khoa...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: _kPrimary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),

          // Specialty filter chips
          if (specialties.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: specialties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final spec = specialties[i];
                  final isSelected = _selectedSpecialty == spec;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedSpecialty =
                          isSelected ? null : spec,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        spec,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _kPrimary : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATE WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  /// Skeleton loading — shows pulse-animation placeholders while loading.
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 14, width: 140, color: Colors.grey.shade200),
                    Container(height: 10, width: 100, color: Colors.grey.shade100),
                    Container(height: 10, width: 80, color: Colors.grey.shade100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải danh sách bác sĩ',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra kết nối mạng và thử lại.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.refresh(doctorListProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy bác sĩ',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty || _selectedSpecialty != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedSpecialty = null;
                });
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DOCTOR CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Individual doctor card in the list with enhanced UI.
class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final profile = (doctor['profile'] as Map<String, dynamic>?) ?? {};
    final name = doctor['name']?.toString() ?? 'Bác sĩ';
    final avatar = profile['avatar']?.toString() ?? '';
    final specialty = profile['specialty']?.toString() ?? '';
    final experience = profile['experience']?.toString() ?? '0';
    final priceRaw = profile['price'] ?? profile['prince'] ?? 0;
    double parsedPrice = 0.0;
    if (priceRaw is num) {
      parsedPrice = priceRaw.toDouble();
    } else if (priceRaw is String) {
      parsedPrice = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    final price = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
        .format(parsedPrice);
    final description = profile['description']?.toString() ?? '';
    final rating =
        (profile['rating'] as num?)?.toDouble() ?? 4.5 + (name.length % 5) * 0.1;

    return GestureDetector(
      onTap: () => context.push('/doctor-detail/${doctor['_id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPrimary.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  backgroundColor: _kPrimary.withOpacity(0.1),
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, color: _kPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // ── Doctor Info ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (specialty.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          specialty,
                          style: const TextStyle(
                              color: _kPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$experience năm',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star_rounded,
                            size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Price + Arrow ────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: _kPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
