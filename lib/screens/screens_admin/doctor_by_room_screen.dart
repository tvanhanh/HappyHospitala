import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_doctors.dart';
import 'add_doctor_info.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kSecondary = Color(0xFF0D47A1);

// We can reuse getAdminActiveDoctors but fetch it inside a FutureProvider and filter
final roomDoctorsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) async {
  final allDoctors = await DoctorService.getAdminActiveDoctors();
  return allDoctors.where((doc) => doc['roomId_id'] == roomId).toList();
});

class DoctorByRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const DoctorByRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<DoctorByRoomScreen> createState() => _DoctorByRoomScreenState();
}

class _DoctorByRoomScreenState extends ConsumerState<DoctorByRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncDoctors = ref.watch(roomDoctorsProvider(widget.roomId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Bác sĩ - ${widget.roomName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: asyncDoctors.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Center(child: Text('Phòng này hiện chưa có bác sĩ nào.', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _kPrimary.withOpacity(0.1),
                    radius: 25,
                    backgroundImage: (doc['avatar'] != null && doc['avatar'].toString().isNotEmpty)
                        ? NetworkImage(doc['avatar'])
                        : null,
                    child: (doc['avatar'] == null || doc['avatar'].toString().isEmpty)
                        ? const Icon(Icons.person, color: _kPrimary)
                        : null,
                  ),
                  title: Text(doc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kPrimary)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(doc['email'] ?? ''),
                      const SizedBox(height: 4),
                      Text('Chuyên khoa: ${doc['specialty']}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: () {
          // Navigate to add doctor screen (if you have one)
          // or show a dialog to assign an existing doctor to this room.
          // For now, we will navigate to the generic AddDoctorScreen or show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng phân công bác sĩ vào phòng đang được phát triển.')),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Bác Sĩ', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
