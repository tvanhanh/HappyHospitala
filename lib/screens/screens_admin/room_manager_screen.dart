import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/models/room.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/doctor_by_room_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/room_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/specialty_provider.dart';
import '../../services/room_service.dart';

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
  final _searchController =
      TextEditingController(); // Controller cho thanh tìm kiếm

  String _status = 'Available';
  String? _selectedSpecialtyId;
  String _searchQuery = ''; // Biến lưu từ khóa tìm kiếm công thức flat

  @override
  void initState() {
    super.initState();
    _selectedSpecialtyId = widget.specialtyId;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom({String? id}) async {
    final roomNumber = _roomNumberController.text.trim();
    // Lấy text từ ô nhập Tầng và ép kiểu sang số nguyên (int). Nếu rỗng hoặc lỗi thì mặc định là tầng 1.
    final floor = int.tryParse(_floorController.text.trim()) ?? 1;

    if (roomNumber.isEmpty) {
      _showErrorSnackBar('Số phòng không được để trống!');
      return;
    }

    if (_selectedSpecialtyId == null) {
      _showErrorSnackBar('Vui lòng chọn một chuyên khoa!');
      return;
    }

    // 1. FRONTEND VALIDATION CHẠY TRƯỚC:
    // Lấy danh sách phòng hiện tại đang có trong cache của Provider để check nhanh
    final currentRoomsAsync = ref.read(roomProvider(widget.specialtyId));

    if (currentRoomsAsync.hasValue) {
      final existingRooms = currentRoomsAsync.value!;
      // Kiểm tra xem số phòng nhập vào đã tồn tại trong danh sách chưa (trừ chính nó nếu là đang sửa)
      final isDuplicate = existingRooms.any((r) =>
          r.roomNumber.toLowerCase() == roomNumber.toLowerCase() && r.id != id);

      if (isDuplicate) {
        _showErrorSnackBar(
            'Xử lý thất bại: Số phòng này đã tồn tại trên giao diện!');
        return; // Chặn lại luôn, không thèm gọi API nữa
      }
    }

    // 2. NẾU FRONTEND VƯỢT QUA -> MỚI GỌI API SERVICE
    final errorMessage = await RoomService.saveRoom(
      id: id,
      roomNumber: roomNumber,
      floor: floor, // TRUYỀN BIẾN FLOOR ĐÃ ÉP KIỂU SANG SỐ VÀO ĐÂY
      status: _status,
      specialtyId: _selectedSpecialtyId!,
    );

    // 3. XỬ LÝ KẾT QUẢ TRẢ VỀ
    if (errorMessage == null) {
      _roomNumberController.clear();
      _floorController.text = '1'; // Reset lại form
      ref.invalidate(roomProvider(widget.specialtyId));
      ref.invalidate(roomProvider(null));
      if (mounted) Navigator.pop(context);
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  // 2. XÓA PHÒNG VIA SERVICE
  Future<void> _deleteRoom(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.red)),
        content: const Text(
            'Bạn có chắc chắn muốn xóa phòng này không? Các dữ liệu liên quan có thể bị ảnh hưởng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final errorMessage = await RoomService.deleteRoom(id);

    if (errorMessage == null) {
      ref.invalidate(roomProvider(widget.specialtyId));
      ref.invalidate(roomProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa phòng thành công!')));
      }
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
      );
    }
  }

  // DIALOG THÊM SỬA
  void _showFormDialog(
      {String? id,
      String? initialRoom,
      int? initialFloor,
      String? initialStatus,
      String? initialSpecId}) {
    final isEditing = id != null;

    if (isEditing) {
      _roomNumberController.text = initialRoom ?? '';
      _floorController.text = initialFloor?.toString() ?? '1';
      _status = initialStatus ?? 'Available';
      _selectedSpecialtyId = initialSpecId;
    } else {
      _roomNumberController.clear();
      _floorController.text = '1';
      _status = 'Available';
      _selectedSpecialtyId = widget.specialtyId;
    }

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final asyncSpecialties = dialogRef.watch(specialtyProvider);

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(
                  isEditing ? 'Sửa Phòng Khám' : 'Thêm Phòng Mới',
                  style: const TextStyle(
                      color: _kPrimary, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _roomNumberController,
                          decoration: InputDecoration(
                            labelText: 'Số phòng (VD: P101)',
                            prefixIcon: const Icon(Icons.meeting_room_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _floorController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tầng (VD: 1)',
                            prefixIcon: const Icon(Icons.layers_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        asyncSpecialties.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Text('Lỗi tải C.Khoa: $err',
                              style: const TextStyle(color: Colors.red)),
                          data: (specialties) {
                            if (specialties.isEmpty)
                              return const Text(
                                  'Vui lòng tạo Chuyên Khoa trước!');
                            return DropdownButtonFormField<String>(
                              value: _selectedSpecialtyId,
                              decoration: InputDecoration(
                                labelText: 'Thuộc Chuyên Khoa',
                                prefixIcon:
                                    const Icon(Icons.local_hospital_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: specialties
                                  .map((spec) => DropdownMenuItem(
                                        value: spec.id,
                                        child: Text(spec.name),
                                      ))
                                  .toList(),
                              onChanged: (val) => setStateDialog(
                                  () => _selectedSpecialtyId = val),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Trạng thái hoạt động',
                            prefixIcon: const Icon(Icons.toggle_on_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Available',
                                child: Text('Sẵn sàng hoạt động (Available)')),
                            DropdownMenuItem(
                                value: 'Maintenance',
                                child: Text('Đang bảo trì (Maintenance)')),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setStateDialog(() => _status = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                        const Text('Hủy', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveRoom(id: id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEditing ? 'Cập Nhật' : 'Tạo Mới'),
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
    final asyncSpecialties = ref.watch(specialtyProvider);
    final specialtiesList = asyncSpecialties.value ?? [];

    // Hàm hỗ trợ: Tìm tên chuyên khoa từ ID
    String getSpecialtyName(String? id) {
      if (id == null || id.isEmpty) return 'Chưa phân khoa';
      try {
        return specialtiesList.firstWhere((s) => s.id == id).name;
      } catch (e) {
        return 'Chưa phân khoa';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: asyncRooms.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Lỗi: $err')),
                  data: (rooms) {
                    // 1. LỌC THEO TỪ KHÓA TÌM KIẾM
                    final filteredRooms = rooms.where((room) {
                      return room.roomNumber
                          .toLowerCase()
                          .contains(_searchQuery);
                    }).toList();

                    if (filteredRooms.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Không tìm thấy phòng khám nào phù hợp.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    // 2. THUẬT TOÁN GOM NHÓM PHÒNG THEO CHUYÊN KHOA
                    final Map<String, List<Room>> groupedRooms = {};
                    for (final room in filteredRooms) {
                      final specName = getSpecialtyName(room.specialtyId);
                      if (!groupedRooms.containsKey(specName)) {
                        groupedRooms[specName] = [];
                      }
                      groupedRooms[specName]!.add(room);
                    }

                    // Sắp xếp tên chuyên khoa theo thứ tự bảng chữ cái (A-Z)
                    final sortedSpecialties = groupedRooms.keys.toList()
                      ..sort();
                    final activeDoctors = asyncActiveDoctors.value ?? [];

                    // 3. VẼ GIAO DIỆN THEO TỪNG NHÓM
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: sortedSpecialties.length,
                      itemBuilder: (context, index) {
                        final specName = sortedSpecialties[index];
                        final roomsInSpec = groupedRooms[specName]!;

                        // Sắp xếp các phòng trong cùng 1 khoa theo số phòng
                        roomsInSpec.sort(
                            (a, b) => a.roomNumber.compareTo(b.roomNumber));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- HEADER TÊN CHUYÊN KHOA ---
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 12.0, left: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _kPrimary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.local_hospital_rounded,
                                        color: _kPrimary,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    specName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${roomsInSpec.length} phòng',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // --- DANH SÁCH CÁC PHÒNG THUỘC KHOA ĐÓ ---
                            ...roomsInSpec.map((room) {
                              final doctorInRoom = activeDoctors.firstWhere(
                                (d) => d['roomId_id'] == room.id,
                                orElse: () => <String, dynamic>{},
                              );
                              final doctorName = doctorInRoom['name'];

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DoctorByRoomScreen(
                                          roomId: room.id,
                                          roomName: room.roomNumber,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: room.status == 'Available'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.meeting_room,
                                            color: room.status == 'Available'
                                                ? Colors.green
                                                : Colors.red,
                                            size: 28),
                                      ),
                                      title: Text('Phòng ${room.roomNumber}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: _kPrimary)),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          doctorName != null
                                              ? 'Tầng ${room.floor} • BS: $doctorName'
                                              : 'Tầng ${room.floor} • Chưa có bác sĩ',
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: room.status == 'Available'
                                                  ? Colors.green
                                                  : Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(room.status,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Sửa phòng',
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.orange),
                                            onPressed: () => _showFormDialog(
                                              id: room.id,
                                              initialRoom: room.roomNumber,
                                              initialFloor: room.floor,
                                              initialStatus: room.status,
                                              initialSpecId: room.specialtyId,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Xóa phòng',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteRoom(room.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo Phòng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // WIDGET THANH TÌM KIẾM ĐÃ ĐƯỢC XỬ LÝ FIX BÓNG ĐỔ KHÔNG BỊ LỖI BOXSHADOW
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase().trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo số phòng...',
            prefixIcon: const Icon(Icons.search, color: _kPrimary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
