import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/specialty_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/room.dart';
import '../../services/config.dart';
import 'room_manager_screen.dart';

const Color _kPrimary = Color(0xFF1565C0);

class SpecialtyManagerScreen extends ConsumerStatefulWidget {
  const SpecialtyManagerScreen({super.key});

  @override
  ConsumerState<SpecialtyManagerScreen> createState() => _SpecialtyManagerScreenState();
}

class _SpecialtyManagerScreenState extends ConsumerState<SpecialtyManagerScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  Future<void> _addSpecialty(List<String> existingRoomIds, List<Map<String, dynamic>> newRooms) async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên chuyên khoa không được để trống')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('$baseUrl/specialties'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'imageUrl': imageUrl.isEmpty ? 'https://cdn-icons-png.flaticon.com/512/2864/2864303.png' : imageUrl,
        'existingRoomIds': existingRoomIds,
        'newRooms': newRooms,
      }),
    );

    if (res.statusCode == 201) {
      _nameController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      ref.invalidate(specialtyProvider);
      ref.invalidate(roomProvider(null));
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${res.body}')),
        );
      }
    }
  }

  void _showAddDialog() {
    List<String> selectedRoomIds = [];
    List<Map<String, dynamic>> newRooms = [];
    final newRoomNumberController = TextEditingController();
    final newRoomFloorController = TextEditingController(text: '1');
    bool onlyRoomsWithDoctors = false;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final asyncRooms = dialogRef.watch(roomProvider(null));
          final asyncActiveDoctors = dialogRef.watch(activeDoctorsProvider);

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Thêm Chuyên Khoa'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Tên chuyên khoa (VD: Tim mạch)'),
                        ),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Mô tả (Tùy chọn)'),
                        ),
                        TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(labelText: 'Link ảnh URL (Tùy chọn)'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Chọn phòng khám đã có:', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () {
                                setStateDialog(() {
                                  onlyRoomsWithDoctors = !onlyRoomsWithDoctors;
                                });
                              },
                              icon: Icon(
                                onlyRoomsWithDoctors ? Icons.filter_alt : Icons.filter_alt_off,
                                size: 16,
                                color: _kPrimary,
                              ),
                              label: Text(
                                onlyRoomsWithDoctors ? 'Tất cả phòng' : 'Chỉ phòng có BS',
                                style: const TextStyle(fontSize: 12, color: _kPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        asyncRooms.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Lỗi tải phòng: $e'),
                          data: (rooms) {
                            if (rooms.isEmpty) return const Text('Chưa có phòng nào.');
                            
                            final activeDoctors = asyncActiveDoctors.value ?? [];
                            
                            var filteredRooms = rooms;
                            if (onlyRoomsWithDoctors) {
                              filteredRooms = rooms.where((r) {
                                return activeDoctors.any((d) => d['roomId_id'] == r.id);
                              }).toList();
                            }
                            
                            if (filteredRooms.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Không có phòng nào phù hợp.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              );
                            }

                            return Wrap(
                              spacing: 8,
                              children: filteredRooms.map((r) {
                                final doctorInRoom = activeDoctors.firstWhere(
                                  (d) => d['roomId_id'] == r.id,
                                  orElse: () => <String, dynamic>{},
                                );
                                final doctorName = doctorInRoom['name'];
                                final hasDoctor = doctorName != null;
                                final isSelected = selectedRoomIds.contains(r.id);

                                return FilterChip(
                                  avatar: hasDoctor 
                                      ? const Icon(Icons.person, size: 16, color: Colors.blue) 
                                      : null,
                                  label: Text(
                                    hasDoctor ? '${r.roomNumber} ($doctorName)' : r.roomNumber,
                                    style: TextStyle(
                                      color: hasDoctor ? Colors.blue.shade900 : Colors.black87,
                                      fontWeight: hasDoctor ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setStateDialog(() {
                                      if (val) {
                                        selectedRoomIds.add(r.id);
                                      } else {
                                        selectedRoomIds.remove(r.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Hoặc thêm phòng mới:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newRoomNumberController,
                                decoration: const InputDecoration(labelText: 'Số phòng (VD: P101)', isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: newRoomFloorController,
                                decoration: const InputDecoration(labelText: 'Tầng', isDense: true),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                if (newRoomNumberController.text.trim().isNotEmpty) {
                                  setStateDialog(() {
                                    newRooms.add({
                                      'roomNumber': newRoomNumberController.text.trim(),
                                      'floor': int.tryParse(newRoomFloorController.text.trim()) ?? 1,
                                    });
                                    newRoomNumberController.clear();
                                  });
                                }
                              },
                            )
                          ],
                        ),
                        if (newRooms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...newRooms.map((nr) => ListTile(
                            dense: true,
                            title: Text('Phòng: ${nr['roomNumber']}'),
                            subtitle: Text('Tầng: ${nr['floor']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                setStateDialog(() {
                                  newRooms.remove(nr);
                                });
                              },
                            ),
                          )),
                        ]
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => _addSpecialty(selectedRoomIds, newRooms),
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                    child: const Text('Thêm'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSpecialties = ref.watch(specialtyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: asyncSpecialties.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (specialties) {
          if (specialties.isEmpty) {
            return const Center(child: Text('Chưa có chuyên khoa nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final spec = specialties[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomManagerScreen(
                          specialtyId: spec.id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kPrimary.withValues(alpha: 0.1),
                      radius: 25,
                      child: spec.imageUrl.isNotEmpty && spec.imageUrl.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                spec.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.local_hospital, color: _kPrimary),
                              ),
                            )
                          : const Icon(Icons.local_hospital, color: _kPrimary),
                    ),
                    title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
                    subtitle: Text(spec.description.isNotEmpty ? spec.description : 'Không có mô tả'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
