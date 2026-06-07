import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/room_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../services/config.dart';
import 'doctor_by_room_screen.dart';

const Color _kPrimary = Color(0xFF1565C0);

class RoomManagerScreen extends ConsumerStatefulWidget {
  final String? specialtyId;
  final String? specialtyName;
  const RoomManagerScreen({super.key, this.specialtyId, this.specialtyName});

  @override
  ConsumerState<RoomManagerScreen> createState() => _RoomManagerScreenState();
}

class _RoomManagerScreenState extends ConsumerState<RoomManagerScreen> {
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  String _status = 'Available';
  bool _isLinkingExisting = false;
  String? _selectedExistingRoomId;
  bool _onlyRoomsWithDoctors = false;

  Future<void> _addRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (_isLinkingExisting) {
      if (_selectedExistingRoomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn một phòng để liên kết')),
        );
        return;
      }

      // Link existing room by calling PUT /rooms/:id
      final res = await http.put(
        Uri.parse('$baseUrl/rooms/$_selectedExistingRoomId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'specialtyId': widget.specialtyId,
        }),
      );

      if (res.statusCode == 200) {
        _selectedExistingRoomId = null;
        ref.invalidate(roomProvider(widget.specialtyId));
        ref.invalidate(roomProvider(null));
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi liên kết: ${res.body}')),
          );
        }
      }
    } else {
      // Create new room (existing logic, but passing specialtyId)
      final roomNumber = _roomNumberController.text.trim();
      final floor = int.tryParse(_floorController.text.trim()) ?? 1;

      if (roomNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số phòng không được để trống')),
        );
        return;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomNumber': roomNumber,
          'floor': floor,
          'status': _status,
          if (widget.specialtyId != null) 'specialtyId': widget.specialtyId,
        }),
      );

      if (res.statusCode == 201) {
        _roomNumberController.clear();
        _floorController.clear();
        ref.invalidate(roomProvider(widget.specialtyId));
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
  }

  void _showAddDialog() {
    setState(() {
      _isLinkingExisting = false;
      _selectedExistingRoomId = null;
      _onlyRoomsWithDoctors = false;
    });

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final asyncRooms = dialogRef.watch(roomProvider(null));
          final asyncActiveDoctors = dialogRef.watch(activeDoctorsProvider);

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Thêm / Liên Kết Phòng'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tạo phòng mới', style: TextStyle(fontSize: 12)),
                              selected: !_isLinkingExisting,
                              onSelected: (val) {
                                setStateDialog(() => _isLinkingExisting = false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Liên kết phòng có sẵn', style: TextStyle(fontSize: 12)),
                              selected: _isLinkingExisting,
                              onSelected: (val) {
                                setStateDialog(() => _isLinkingExisting = true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isLinkingExisting) ...[
                        TextField(
                          controller: _roomNumberController,
                          decoration: const InputDecoration(labelText: 'Số phòng (VD: P101)'),
                        ),
                        TextField(
                          controller: _floorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tầng (VD: 1)'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Trạng thái'),
                          items: ['Available', 'Maintenance']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => _status = val);
                          },
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Chọn phòng có sẵn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            TextButton.icon(
                              onPressed: () {
                                setStateDialog(() {
                                  _onlyRoomsWithDoctors = !_onlyRoomsWithDoctors;
                                });
                              },
                              icon: Icon(
                                _onlyRoomsWithDoctors ? Icons.filter_alt : Icons.filter_alt_off,
                                size: 14,
                                color: _kPrimary,
                              ),
                              label: Text(
                                _onlyRoomsWithDoctors ? 'Tất cả' : 'Chỉ phòng có BS',
                                style: const TextStyle(fontSize: 11, color: _kPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        asyncRooms.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Lỗi tải phòng: $e'),
                          data: (rooms) {
                            // Filter rooms that don't belong to this specialty yet
                            final availableRooms = rooms.where((r) => r.specialtyId == null).toList();
                            
                            final activeDoctors = asyncActiveDoctors.value ?? [];
                            
                            var filteredRooms = availableRooms;
                            if (_onlyRoomsWithDoctors) {
                              filteredRooms = availableRooms.where((r) {
                                return activeDoctors.any((d) => d['roomId_id'] == r.id);
                              }).toList();
                            }
                            
                            if (filteredRooms.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('Không có phòng nào trống phù hợp.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedExistingRoomId,
                              hint: const Text('Chọn phòng...'),
                              isExpanded: true,
                              items: filteredRooms.map((r) {
                                final doctorInRoom = activeDoctors.firstWhere(
                                  (d) => d['roomId_id'] == r.id,
                                  orElse: () => <String, dynamic>{},
                                );
                                final doctorName = doctorInRoom['name'];
                                final displayName = doctorName != null 
                                    ? 'Phòng ${r.roomNumber} (BS. $doctorName)' 
                                    : 'Phòng ${r.roomNumber}';
                                return DropdownMenuItem(
                                  value: r.id,
                                  child: Text(displayName),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setStateDialog(() => _selectedExistingRoomId = val);
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: _addRoom,
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                    child: Text(_isLinkingExisting ? 'Liên Kết' : 'Thêm'),
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
    final asyncRooms = ref.watch(roomProvider(widget.specialtyId));
    final asyncActiveDoctors = ref.watch(activeDoctorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: widget.specialtyId != null 
          ? AppBar(
              title: Text('Phòng khám - ${widget.specialtyName ?? "Chuyên khoa"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: _kPrimary,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: asyncRooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(child: Text('Chưa có phòng nào.'));
          }
          
          final activeDoctors = asyncActiveDoctors.value ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              
              // Find doctor in this room
              final doctorInRoom = activeDoctors.firstWhere(
                (d) => d['roomId_id'] == room.id,
                orElse: () => <String, dynamic>{},
              );
              final doctorName = doctorInRoom['name'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorByRoomScreen(
                          roomId: room.id,
                          roomName: room.roomNumber,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: room.status == 'Available' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Icon(Icons.meeting_room, color: room.status == 'Available' ? Colors.green : Colors.red),
                    ),
                    title: Text('${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      doctorName != null 
                          ? 'Tầng ${room.floor} • Bác sĩ: $doctorName' 
                          : 'Tầng ${room.floor} • Chưa có bác sĩ'
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: room.status == 'Available' ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(room.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
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
