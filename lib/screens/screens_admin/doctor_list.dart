import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_doctors.dart';
import '../../providers/specialty_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/admin_stats_provider.dart';
import '../../models/specialty.dart';
import '../../models/room.dart';

// --- PALETTE MÀU HIỆN ĐẠI ---
const Color _kPrimary = Color(0xFF1565C0);
const Color _kSecondary = Color(0xFF0D47A1);

// --- PROVIDERS ---
final activeDoctorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await DoctorService.getAdminActiveDoctors();
});

final pendingDoctorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await DoctorService.getPendingDoctors();
});

final rejectedDoctorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await DoctorService.getRejectedDoctors();
});

class DoctorListScreen extends ConsumerStatefulWidget {
  const DoctorListScreen({super.key});

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApproveDialog(Map<String, dynamic> doctorUser) {
    String? selectedSpecialtyId;
    String? selectedSpecialtyName;
    String? selectedRoom;

    final String bio = doctorUser['bio'] ?? 'Chưa cập nhật tiểu sử.';
    final int experience = doctorUser['experience_years'] ?? 0;
    final List education = doctorUser['education'] ?? [];
    final List certs = doctorUser['certifications_urls'] ?? [];
    final String specialtyText = doctorUser['specialty'] ?? 'Chưa cập nhật';

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, dialogRef, _) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final asyncSpecialties = dialogRef.watch(specialtyProvider);
                final asyncRooms = dialogRef.watch(roomProvider(null));

                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints:
                        const BoxConstraints(maxWidth: 500, maxHeight: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 50, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text(
                          'Duyệt Hồ Sơ Bác Sĩ',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thông tin chi tiết của bác sĩ ${doctorUser['name']}',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Scrollable profile details
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chuyên môn: $specialtyText',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Kinh nghiệm: $experience năm',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                const Text('Giới thiệu:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(bio),
                                const SizedBox(height: 12),
                                if (education.isNotEmpty) ...[
                                  const Text('Học vấn:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...education.map((e) => Text(
                                      '- ${e['degree']} (${e['university']} - ${e['year']})')),
                                  const SizedBox(height: 12),
                                ],
                                if (certs.isNotEmpty) ...[
                                  const Text('Chứng chỉ:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...certs.map((c) => Text('- $c',
                                      style:
                                          const TextStyle(color: Colors.blue))),
                                  const SizedBox(height: 16),
                                ],

                                const Divider(),
                                const SizedBox(height: 16),

                                // Specialty Dropdown
                                asyncSpecialties.when(
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (e, _) =>
                                      Text('Lỗi tải Chuyên khoa: $e'),
                                  data: (specialties) =>
                                      DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Phân Khoa',
                                      prefixIcon: const Icon(
                                          Icons.local_hospital,
                                          color: _kPrimary),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    items: specialties
                                        .map((s) => DropdownMenuItem(
                                            value: s.id, child: Text(s.name)))
                                        .toList(),
                                    onChanged: (selectedId) =>
                                        setDialogState(() {
                                      selectedSpecialtyId = selectedId;
                                      selectedSpecialtyName = specialties
                                          .firstWhere((s) => s.id == selectedId)
                                          .name;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Room Dropdown
                                asyncRooms.when(
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (e, _) => Text('Lỗi tải Phòng: $e'),
                                  data: (rooms) {
                                    final availableRooms = rooms
                                        .where((r) => r.status == 'Available')
                                        .toList();
                                    return DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Phân Phòng khám',
                                        prefixIcon: const Icon(
                                            Icons.meeting_room,
                                            color: _kPrimary),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      items: availableRooms
                                          .map((r) => DropdownMenuItem(
                                              value: r.id,
                                              child: Text(r.roomNumber)))
                                          .toList(),
                                      onChanged: (val) => setDialogState(
                                          () => selectedRoom = val),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Hủy'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final res = await DoctorService.rejectDoctor(
                                      doctorUser['_id']);
                                  if (res == 'success') {
                                    ref.invalidate(pendingDoctorsProvider);
                                    ref.invalidate(rejectedDoctorsProvider);
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Đã từ chối hồ sơ!'),
                                            backgroundColor: Colors.orange),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(res),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Từ Chối',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedRoom == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Vui lòng chọn Phòng khám')),
                                    );
                                    return;
                                  }

                                  final roomsList = asyncRooms.value ?? [];
                                  final roomObj = roomsList.firstWhere(
                                    (r) => r.id == selectedRoom,
                                    orElse: () => Room(
                                        id: '',
                                        roomNumber: '',
                                        floor: 1,
                                        status: 'Available'),
                                  );

                                  final finalSpecialtyId =
                                      selectedSpecialtyId ??
                                          roomObj.specialtyId ??
                                          '';

                                  String finalSpecialtyName = '';
                                  if (finalSpecialtyId.isNotEmpty) {
                                    final specialtiesList =
                                        asyncSpecialties.value ?? [];
                                    final specObj = specialtiesList.firstWhere(
                                      (s) => s.id == finalSpecialtyId,
                                      orElse: () => Specialty(
                                          id: '',
                                          name: '',
                                          description: '',
                                          imageUrl: ''),
                                    );
                                    finalSpecialtyName = specObj.name;
                                  }

                                  final res = await DoctorService.approveDoctor(
                                      doctorUser['_id'],
                                      finalSpecialtyId,
                                      finalSpecialtyName,
                                      selectedRoom!);

                                  if (res == 'success') {
                                    ref.invalidate(pendingDoctorsProvider);
                                    ref.invalidate(activeDoctorsProvider);
                                    ref.invalidate(rejectedDoctorsProvider);
                                    ref.invalidate(adminStatsProvider);
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Duyệt thành công!'),
                                            backgroundColor: Colors.green),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(res),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Phê Duyệt',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Đang Hoạt Động', icon: Icon(Icons.verified_user)),
            Tab(text: 'Chờ Duyệt', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Từ Chối', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveDoctorsTab(),
          _buildPendingDoctorsTab(),
          _buildRejectedDoctorsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/admin/add-doctor');
          if (result == true) ref.invalidate(activeDoctorsProvider);
        },
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Tạo Hồ Sơ"),
      ),
    );
  }

  Widget _buildActiveDoctorsTab() {
    final asyncData = ref.watch(activeDoctorsProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (doctors) {
        if (doctors.isEmpty) {
          return const Center(child: Text('Chưa có bác sĩ nào.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index], isActive: true);
          },
        );
      },
    );
  }

  Widget _buildPendingDoctorsTab() {
    final asyncData = ref.watch(pendingDoctorsProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (doctors) {
        if (doctors.isEmpty) {
          return const Center(child: Text('Không có hồ sơ chờ duyệt.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index], isActive: false);
          },
        );
      },
    );
  }

  Widget _buildRejectedDoctorsTab() {
    final asyncData = ref.watch(rejectedDoctorsProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (doctors) {
        if (doctors.isEmpty) {
          return const Center(child: Text('Không có hồ sơ bị từ chối.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index],
                isActive: false, isRejected: true);
          },
        );
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor,
      {required bool isActive, bool isRejected = false}) {
    String name = doctor['doctorName'] ?? doctor['name'] ?? 'Không rõ tên';
    String email = doctor['email'] ?? 'Chưa cập nhật';
    String avatarUrl = doctor['avatar'] ?? '';
    Color avatarColor = Colors.primaries[name.length % Colors.primaries.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: avatarColor.withValues(alpha: 0.1),
          backgroundImage: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
              ? NetworkImage(avatarUrl)
              : null,
          child: (avatarUrl.isEmpty || !avatarUrl.startsWith('http'))
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                )
              : null,
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_hospital, size: 14, color: _kPrimary),
                  const SizedBox(width: 4),
                  Text(doctor['specialty'] ?? 'Chưa phân công',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 12),
                  const Icon(Icons.meeting_room, size: 14, color: _kPrimary),
                  const SizedBox(width: 4),
                  Text(doctor['room'] ?? 'Chưa phân công',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 12),
                  const Icon(Icons.monetization_on,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                      doctor['consultationFee'] != null
                          ? '${doctor['consultationFee']} VNĐ'
                          : '0 VNĐ',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ]
          ],
        ),
        trailing: isActive
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Cập nhật giá khám',
                    icon: const Icon(Icons.edit_note, color: Colors.orange),
                    onPressed: () => _showUpdateFeeDialog(doctor),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/doctor-detail/${doctor['_id']}'),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Chi Tiết'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary)),
                  ),
                ],
              )
            : isRejected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Bị từ chối',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (doctor['rejection_reason'] != null &&
                              doctor['rejection_reason'].toString().isNotEmpty)
                            Text(
                              doctor['rejection_reason'],
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 11),
                              textAlign: TextAlign.right,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(doctor),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt Lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(doctor),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
      ),
    );
  }

  void _showUpdateFeeDialog(Map<String, dynamic> doctor) {
    final feeController = TextEditingController(
        text: doctor['consultationFee']?.toString() ?? '0');
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.green),
                const SizedBox(width: 10),
                const Text('Cập nhật Giá Khám',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bác sĩ: ${doctor['doctorName'] ?? doctor['name']}'),
                const SizedBox(height: 16),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Giá khám (VNĐ)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.price_change),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final newFee =
                            int.tryParse(feeController.text.trim()) ?? 0;
                        setStateDialog(() => isUpdating = true);
                        final msg = await DoctorService.updateDoctorFee(
                            doctor['_id'], newFee);
                        setStateDialog(() => isUpdating = false);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));
                          ref.invalidate(activeDoctorsProvider);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Cập Nhật'),
              ),
            ],
          );
        });
      },
    );
  }
}
