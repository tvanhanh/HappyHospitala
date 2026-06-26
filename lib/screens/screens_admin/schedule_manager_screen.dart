import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/doctor_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/specialty_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/schedule_service.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF5F7FA);

class ScheduleManagerScreen extends ConsumerStatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  ConsumerState<ScheduleManagerScreen> createState() =>
      _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends ConsumerState<ScheduleManagerScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedFilterSpecId; // null nghĩa là hiển thị Tất cả các Khoa

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- BOTTOM SHEET CHỌN BÁC SĨ ---
  void _showDoctorPickerBottomSheet(List<dynamic> doctors,
      StateSetter setDialogState, Function(String) onSelected) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredDoctors = doctors.where((d) {
              final name = d['name']?.toString() ?? 'Vô danh';
              return name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text('Chọn Bác Sĩ Trực',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      onChanged: (val) =>
                          setSheetState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên bác sĩ...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredDoctors.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy bác sĩ nào.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredDoctors.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final doc = filteredDoctors[index];

                              final rawId = doc['_id'];
                              final docId =
                                  (rawId != null) ? rawId.toString() : '';
                              final docName =
                                  doc['name']?.toString() ?? 'Vô danh';
                              final docAvatar = doc['avatar']?.toString() ?? '';
                              final experience =
                                  doc['experience_years']?.toString() ?? '0';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: docAvatar.isNotEmpty
                                      ? NetworkImage(docAvatar)
                                      : null,
                                  child: docAvatar.isEmpty
                                      ? const Icon(Icons.person,
                                          color: _kPrimary)
                                      : null,
                                ),
                                title: Text('BS. $docName',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: Text('Kinh nghiệm: $experience năm',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    if (docId.isEmpty || docId == 'null') {
                                      _showMessage('Lỗi: Bác sĩ thiếu ID!',
                                          isError: true);
                                      return;
                                    }
                                    onSelected(docId);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: _kPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                  child: const Text('Chọn'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DIALOG THÊM / SỬA LỊCH ---
  void _showScheduleDialog({Map<String, dynamic>? existingSchedule}) {
    String? selectedSpecId;
    String? selectedRoomId;
    String? selectedDoctorId;
    String selectedShift = 'Sáng';

    if (existingSchedule != null) {
      selectedSpecId = existingSchedule['specialtyId'] != null
          ? existingSchedule['specialtyId']['_id']?.toString()
          : null;
      selectedRoomId = existingSchedule['roomId'] != null
          ? existingSchedule['roomId']['_id']?.toString()
          : null;
      selectedDoctorId = existingSchedule['doctorId'] != null
          ? (existingSchedule['doctorId'] is Map
              ? existingSchedule['doctorId']['_id']?.toString()
              : existingSchedule['doctorId']?.toString())
          : null;
      selectedShift = existingSchedule['shift'] ?? 'Sáng';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final asyncSpecialties = ref.watch(specialtyProvider);
            final asyncRooms = ref.watch(roomProvider(null));
            final asyncDoctors = ref.watch(activeDoctorsProvider);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                final rooms = asyncRooms.value
                        ?.where((r) => r.specialtyId == selectedSpecId)
                        .toList() ??
                    [];
                final doctors = asyncDoctors.value
                        ?.where((d) =>
                            d['specialtyId_id']?.toString() == selectedSpecId ||
                            d['specialtyId']?.toString() == selectedSpecId)
                        .toList() ??
                    [];
                String getSelectedDoctorName() {
                  if (selectedDoctorId == null || selectedDoctorId == 'null')
                    return 'Chưa chọn bác sĩ';

                  final allDoctors = asyncDoctors.value;
                  if (allDoctors == null || allDoctors.isEmpty)
                    return 'BS. Đang tải...';

                  // LOGIC TÌM KIẾM CẢ 2 CỬA:
                  // 1. Nếu ID bạn đang cầm là Doctor ID (655)
                  // 2. Hoặc nếu ID bạn đang cầm là User ID (653)
                  final doc = allDoctors.firstWhere(
                    (d) {
                      String doctorId = d['_id']?.toString().trim() ?? '';

                      // Lấy userId thực tế trong object doctor (xử lý cả trường hợp populate hay chưa)
                      final userObj = d['userId'];
                      String userId = (userObj is Map)
                          ? (userObj['_id']?.toString().trim() ?? '')
                          : (userObj?.toString().trim() ?? '');

                      String targetId = selectedDoctorId!.trim();

                      // So sánh với cả 2 trường hợp
                      return doctorId == targetId || userId == targetId;
                    },
                    orElse: () => {},
                  );

                  if (doc.isEmpty) {
                    return 'BS. Không tồn tại (ID: ${selectedDoctorId!.substring(selectedDoctorId!.length - 3)})';
                  }

                  // Lấy tên
                  final name =
                      doc['userId']?['fullName'] ?? doc['name'] ?? 'Vô danh';
                  return 'BS. $name';
                }

                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: _kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.event_note_rounded,
                                  color: _kPrimary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      existingSchedule == null
                                          ? 'Phân Công Lịch Trực'
                                          : 'Chỉnh Sửa Lịch Trực',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E))),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedSpecId,
                          decoration: InputDecoration(
                            labelText: '1. Chuyên Khoa',
                            prefixIcon:
                                const Icon(Icons.local_hospital_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: (asyncSpecialties.value ?? [])
                              .map((s) => DropdownMenuItem(
                                  value: s.id, child: Text(s.name)))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedSpecId = val;
                              selectedRoomId = null;
                              selectedDoctorId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRoomId,
                          decoration: InputDecoration(
                            labelText: '2. Phòng Khám',
                            prefixIcon: const Icon(Icons.meeting_room_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: rooms
                              .map((r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text('Phòng ${r.roomNumber}')))
                              .toList(),
                          onChanged: selectedSpecId == null
                              ? null
                              : (val) =>
                                  setDialogState(() => selectedRoomId = val),
                          hint: Text(selectedSpecId == null
                              ? 'Vui lòng chọn Khoa trước'
                              : 'Chọn phòng'),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: selectedSpecId == null
                              ? () => _showMessage('Vui lòng chọn Khoa trước',
                                  isError: true)
                              : () => _showDoctorPickerBottomSheet(
                                      doctors, setDialogState, (id) {
                                    setDialogState(() => selectedDoctorId = id);
                                  }),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: '3. Bác Sĩ Trực',
                              prefixIcon: const Icon(Icons.person_outline),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            child: Text(getSelectedDoctorName(),
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedShift,
                          decoration: InputDecoration(
                            labelText: '4. Ca Trực',
                            prefixIcon: const Icon(Icons.wb_sunny_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: ['Sáng', 'Chiều', 'Tối', 'Cả ngày']
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text('Ca $s')))
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => selectedShift = val!),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: const Text('Hủy',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedRoomId == null ||
                                      selectedRoomId == 'null' ||
                                      selectedRoomId!.isEmpty ||
                                      selectedDoctorId == null ||
                                      selectedDoctorId == 'null' ||
                                      selectedDoctorId!.isEmpty) {
                                    _showMessage(
                                        'Vui lòng chọn đầy đủ Phòng và Bác sĩ!',
                                        isError: true);
                                    return;
                                  }

                                  final dateString = DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate);
                                  String? err;

                                  if (existingSchedule == null) {
                                    err = await ScheduleService.assignSchedule(
                                      doctorId: selectedDoctorId!,
                                      roomId: selectedRoomId!,
                                      date: dateString,
                                      shift: selectedShift,
                                    );
                                  } else {
                                    err = await ScheduleService.updateSchedule(
                                      id: existingSchedule['_id'],
                                      doctorId: selectedDoctorId!,
                                      roomId: selectedRoomId!,
                                      date: dateString,
                                      shift: selectedShift,
                                    );
                                  }

                                  if (err == null) {
                                    ref.invalidate(scheduleByDateProvider);
                                    if (context.mounted) Navigator.pop(context);
                                    _showMessage(existingSchedule == null
                                        ? 'Phân công lịch thành công!'
                                        : 'Đã cập nhật lịch!');
                                  } else {
                                    _showMessage(err, isError: true);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                    existingSchedule == null
                                        ? 'Lưu Phân Công'
                                        : 'Cập Nhật',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
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

  // ============================================================
  // --- BOTTOM SHEET SAO CHÉP LỊCH TRỰC ---
  // ============================================================
  void _showCopyScheduleBottomSheet() {
    // State nội bộ của bottom sheet
    String copyType = 'day'; // 'day' | 'week' | 'month'
    DateTime sourceDate = _selectedDate;
    DateTime? targetDate;
    bool isCopying = false;

    // Hàm tính ngày thứ 2 đầu tuần
    DateTime getMonday(DateTime d) {
      int diff = d.weekday - DateTime.monday;
      return d.subtract(Duration(days: diff));
    }

    // Hàm mô tả nguồn theo từng mode
    String sourceLabel(String type, DateTime src) {
      if (type == 'day') {
        return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(src);
      } else if (type == 'week') {
        final mon = getMonday(src);
        final sun = mon.add(const Duration(days: 6));
        return 'Tuần ${DateFormat('dd/MM').format(mon)} – ${DateFormat('dd/MM/yyyy').format(sun)}';
      } else {
        return DateFormat('MMMM yyyy', 'vi').format(src);
      }
    }

    // Hàm mô tả đích theo từng mode
    String targetLabel(String type, DateTime? tgt) {
      if (tgt == null) return 'Chưa chọn';
      if (type == 'day') {
        return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(tgt);
      } else if (type == 'week') {
        final mon = getMonday(tgt);
        final sun = mon.add(const Duration(days: 6));
        return 'Tuần ${DateFormat('dd/MM').format(mon)} – ${DateFormat('dd/MM/yyyy').format(sun)}';
      } else {
        return DateFormat('MMMM yyyy', 'vi').format(tgt);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.content_copy_rounded,
                              color: _kPrimary, size: 26),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sao Chép Lịch Trực',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E))),
                            SizedBox(height: 2),
                            Text('Nhân bản lịch sang khoảng thời gian khác',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Bước 1: Chọn kiểu sao chép ──
                          const Text('Bước 1: Chọn kiểu sao chép',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _CopyTypeChip(
                                label: 'Theo Ngày',
                                icon: Icons.today_rounded,
                                value: 'day',
                                selected: copyType,
                                onTap: () => setSheetState(() {
                                  copyType = 'day';
                                  targetDate = null;
                                }),
                              ),
                              const SizedBox(width: 10),
                              _CopyTypeChip(
                                label: 'Theo Tuần',
                                icon: Icons.date_range_rounded,
                                value: 'week',
                                selected: copyType,
                                onTap: () => setSheetState(() {
                                  copyType = 'week';
                                  targetDate = null;
                                }),
                              ),
                              const SizedBox(width: 10),
                              _CopyTypeChip(
                                label: 'Theo Tháng',
                                icon: Icons.calendar_month_rounded,
                                value: 'month',
                                selected: copyType,
                                onTap: () => setSheetState(() {
                                  copyType = 'month';
                                  targetDate = null;
                                }),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Bước 2: Nguồn ──
                          const Text('Bước 2: Sao chép TỪ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 10),
                          _InfoBox(
                            icon: Icons.event_note_rounded,
                            color: Colors.blue,
                            label: sourceLabel(copyType, sourceDate),
                            hint: 'Dựa trên ngày đang xem',
                          ),

                          const SizedBox(height: 28),

                          // ── Bước 3: Đích ──
                          const Text('Bước 3: Sao chép ĐẾN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: targetDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                helpText: copyType == 'month'
                                    ? 'Chọn bất kỳ ngày trong tháng đích'
                                    : copyType == 'week'
                                        ? 'Chọn bất kỳ ngày trong tuần đích'
                                        : 'Chọn ngày đích',
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: _kPrimary,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => targetDate = picked);
                              }
                            },
                            child: targetDate == null
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline_rounded,
                                            color: Colors.grey.shade400,
                                            size: 28),
                                        const SizedBox(width: 12),
                                        Text(
                                          copyType == 'month'
                                              ? 'Nhấn để chọn tháng đích...'
                                              : copyType == 'week'
                                                  ? 'Nhấn để chọn tuần đích...'
                                                  : 'Nhấn để chọn ngày đích...',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  )
                                : _InfoBox(
                                    icon: Icons.event_available_rounded,
                                    color: Colors.green,
                                    label: targetLabel(copyType, targetDate),
                                    hint: 'Nhấn để thay đổi',
                                  ),
                          ),

                          // ── Cảnh báo ──
                          if (targetDate != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: Colors.amber.shade700, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Ca trực đã tồn tại ở thời gian đích sẽ được bỏ qua tự động. Dữ liệu gốc sẽ không bị thay đổi.',
                                      style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ── Nút xác nhận ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (targetDate == null || isCopying)
                            ? null
                            : () async {
                                setSheetState(() => isCopying = true);
                                final fromStr =
                                    DateFormat('yyyy-MM-dd').format(sourceDate);
                                final toStr =
                                    DateFormat('yyyy-MM-dd').format(targetDate!);

                                final result = await ScheduleService.copySchedule(
                                  type: copyType,
                                  fromDate: fromStr,
                                  toDate: toStr,
                                );

                                setSheetState(() => isCopying = false);

                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                Navigator.of(ctx).pop();

                                if (result['success'] == true) {
                                  ref.invalidate(scheduleByDateProvider);
                                  final copied = result['copied'] ?? 0;
                                  final skipped = result['skipped'] ?? 0;
                                  final msg = copied > 0
                                      ? 'Đã tạo $copied ca trực mới${skipped > 0 ? ', bỏ qua $skipped ca trùng' : ''}!'
                                      : 'Không có ca nào được tạo (có thể tất cả đã tồn tại).';
                                  _showMessage(msg, isError: copied == 0);
                                } else {
                                  _showMessage(result['message'] ?? 'Lỗi không xác định', isError: true);
                                }
                              },
                        icon: isCopying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.content_copy_rounded,
                                color: Colors.white),
                        label: Text(
                          isCopying ? 'Đang sao chép...' : 'Bắt Đầu Sao Chép',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: targetDate == null
                              ? Colors.grey.shade300
                              : _kPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Xóa lịch trực?', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
            'Hành động này sẽ xóa ca trực khỏi hệ thống. Bệnh nhân sẽ không thể đặt lịch vào ca này nữa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Xóa Bỏ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final err = await ScheduleService.deleteSchedule(id);
      if (err == null) {
        ref.invalidate(scheduleByDateProvider);
        _showMessage('Đã xóa lịch trực!');
      } else {
        _showMessage(err, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final asyncSchedules = ref.watch(scheduleByDateProvider(dateString));
    final asyncSpecialties = ref.watch(specialtyProvider);

    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          // --- BỘ LỌC NGÀY THÁNG BANNER XANH ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => _changeDate(-1),
                  ),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: _kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => _changeDate(1),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- THANH LỌC CHUYÊN KHOA NGANG (FILTER CHIPS HÀNG HIỆU) ---
          asyncSpecialties.when(
            data: (specialties) {
              return Container(
                height: 45,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Nút tất cả khoa
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedFilterSpecId == null,
                        label: const Text('Tất cả Khoa',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onSelected: (_) =>
                            setState(() => _selectedFilterSpecId = null),
                        selectedColor: _kPrimary.withOpacity(0.2),
                        checkmarkColor: _kPrimary,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    // Danh sách các khoa từ server
                    ...specialties.map((spec) {
                      final isSelected = _selectedFilterSpecId == spec.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(spec.name,
                              style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500)),
                          onSelected: (selected) {
                            setState(() => _selectedFilterSpecId =
                                selected ? spec.id : null);
                          },
                          selectedColor: _kPrimary.withOpacity(0.2),
                          checkmarkColor: _kPrimary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
                height: 45,
                child: Center(
                    child: SizedBox(
                        width: 100, child: LinearProgressIndicator()))),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // --- DANH SÁCH LỊCH TRỰC DẠNG DASHBOARD GRID MỚI ---
          Expanded(
            child: asyncSchedules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text('Lỗi: $err',
                      style: const TextStyle(color: Colors.red))),
              data: (schedules) {
                // 1. TIẾN HÀNH LỌC THEO KHOA TRƯỚC KHI HIỂN THỊ
                final filteredSchedules = _selectedFilterSpecId == null
                    ? schedules
                    : schedules.where((s) {
                        final spec = s['specialtyId'];
                        if (spec == null) return false;
                        final specId = (spec is Map)
                            ? spec['_id']?.toString()
                            : spec.toString();
                        return specId == _selectedFilterSpecId;
                      }).toList();

                if (filteredSchedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle),
                          child: Icon(Icons.event_available_rounded,
                              size: 80, color: Colors.blue.shade200),
                        ),
                        const SizedBox(height: 20),
                        Text('Không Có Ca Trực Phù Hợp',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800)),
                      ],
                    ),
                  );
                }

                // 2. GOM NHÓM DỮ LIỆU ĐÃ LỌC THEO CA
                final grouped = {
                  'Sáng': [],
                  'Chiều': [],
                  'Tối': [],
                  'Cả ngày': []
                };
                for (var s in filteredSchedules) {
                  grouped[s['shift']]?.add(s);
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: grouped.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((entry) {
                      final shift = entry.key;
                      final shiftSchedules = entry.value;

                      Color shiftColor = shift == 'Sáng'
                          ? Colors.orange
                          : shift == 'Chiều'
                              ? Colors.orangeAccent.shade700
                              : Colors.indigo;
                      IconData shiftIcon = shift == 'Sáng'
                          ? Icons.wb_twilight
                          : shift == 'Chiều'
                              ? Icons.wb_sunny
                              : Icons.nights_stay;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: shiftColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(shiftIcon,
                                      color: shiftColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text('Ca $shift',
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade900)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text('${shiftSchedules.length} phòng',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: shiftSchedules.map((schedule) {
                                final room = schedule['roomId'];
                                final doctor = schedule['doctorId'];
                                final spec = schedule['specialtyId'];

                                // ĐỌC DỮ LIỆU TỪ DEEP POPULATE
                                String docName = 'Chưa cập nhật';
                                String docAvatar = '';
                                if (doctor != null && doctor['userId'] is Map) {
                                  docName =
                                      doctor['userId']['fullName'] ?? 'Vô danh';
                                  docAvatar = doctor['userId']['avatar'] ?? '';
                                } else if (doctor != null) {
                                  docName = doctor['name'] ?? 'Vô danh';
                                }

                                return Container(
                                  width: 340,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4))
                                    ],
                                    border:
                                        Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                              backgroundImage:
                                                  docAvatar.isNotEmpty
                                                      ? NetworkImage(docAvatar)
                                                      : null,
                                              child: docAvatar.isEmpty
                                                  ? const Icon(Icons.person,
                                                      color: _kPrimary)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('BS. $docName',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Color(
                                                              0xFF1A1A2E)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons.healing_rounded,
                                                          size: 14,
                                                          color: Colors
                                                              .grey.shade500),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                          spec != null
                                                              ? (spec is Map
                                                                  ? spec['name']
                                                                  : 'Khoa')
                                                              : '',
                                                          style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            child: Divider(height: 1)),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                  color: _kPrimary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .meeting_room_rounded,
                                                      size: 16,
                                                      color: _kPrimary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                      room != null
                                                          ? 'P. ${room['roomNumber']}'
                                                          : 'P. --',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _kPrimary)),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.edit_square,
                                                      color: Colors.orange,
                                                      size: 22),
                                                  onPressed: () =>
                                                      _showScheduleDialog(
                                                          existingSchedule:
                                                              schedule),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .delete_sweep_rounded,
                                                      color: Colors.red,
                                                      size: 24),
                                                  onPressed: () =>
                                                      _deleteSchedule(
                                                          schedule['_id']),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'copy_fab',
            onPressed: _showCopyScheduleBottomSheet,
            backgroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.content_copy_rounded, color: _kPrimary),
            label: const Text('Sao Chép',
                style: TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add_fab',
            onPressed: () => _showScheduleDialog(),
            backgroundColor: _kPrimary,
            elevation: 4,
            icon: const Icon(Icons.add_task_rounded, color: Colors.white),
            label: const Text('Phân Công Mới',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ── Widget helper: Chip chọn kiểu sao chép ──
class _CopyTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _CopyTypeChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _kPrimary : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget helper: Box hiển thị thông tin nguồn/đích ──
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String hint;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(hint,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
