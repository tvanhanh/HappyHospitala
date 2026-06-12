import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/room_provider.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kPrimaryDark = Color(0xFF1E3A8A);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class SelectRoomScreen extends ConsumerWidget {
  final String specialtyId;

  const SelectRoomScreen({super.key, required this.specialtyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRooms = ref.watch(roomProvider(specialtyId));

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Chọn Phòng Khám'),
        centerTitle: true,
      ),
      body: asyncRooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải phòng: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
                child: Text('Chuyên khoa này chưa có phòng khám'));
          }

          // Filter only available rooms
          final availableRooms =
              rooms.where((r) => r.status == 'Available').toList();

          if (availableRooms.isEmpty) {
            return const Center(child: Text('Không có phòng khám nào có sẵn'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableRooms.length,
            itemBuilder: (context, index) {
              final room = availableRooms[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/patient/book-appointment/doctors/${room.id}',
                  extra: {'specialtyId': specialtyId, 'roomId': room.id},
                ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.roomNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tầng ${room.floor}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Sẵn sàng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_available,
                                      color: _kPrimary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Phòng ${room.roomNumber}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: _kPrimary, size: 16),
                            ],
                          ),
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
