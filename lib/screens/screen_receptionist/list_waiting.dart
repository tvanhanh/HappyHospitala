import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/receptionist_provider.dart';
import '../../widgets/receptionist_drawer.dart';

// ĐƯA CÁC BIẾN MÀU RA NGOÀI CLASS ĐỂ SỬA LỖI ĐỊNH DANH (UNDEFINED NAME)
const Color kPrimaryColor = Color(0xFF0F172A); 
const Color kBackgroundColor = Color(0xFFF8FAFC); 
const Color kBorderColor = Color(0xFFE2E8F0);

class ListWaitingScreen extends ConsumerStatefulWidget {
  const ListWaitingScreen({super.key});

  @override
  ConsumerState<ListWaitingScreen> createState() => _ListWaitingScreenState();
}

class _ListWaitingScreenState extends ConsumerState<ListWaitingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Tự động fetch dữ liệu mới nhất theo ngày đang chọn khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(receptionistProvider);
      ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receptionistState = ref.watch(receptionistProvider);
    
    // LỌC REAL-TIME: Chỉ lấy những cuộc hẹn có trạng thái là 'checked_in'
    final allWaitingAppointments = receptionistState.appointments
        .where((a) => a.status == 'checked_in')
        .toList();

    // Áp dụng thêm bộ lọc tìm kiếm (Search Bar) nếu có nhập chữ
    final filteredWaitingList = allWaitingAppointments.where((a) {
      final query = _searchQuery.toLowerCase();
      return a.patientName.toLowerCase().contains(query) ||
             a.phone.contains(query) ||
             a.id.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: kBackgroundColor, // ĐÃ SỬA: Thay thế dấu chấm phẩy ';' sai cú pháp thành dấu phẩy ','
      appBar: AppBar(
        title: const Text(
          "Hệ thống Thu ngân - Phòng khám Đa khoa Hòa Bình",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: kBorderColor, height: 1),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Nút Refresh để hỗ trợ lấy dữ liệu thủ công nhanh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: ReceptionistDrawer(
        selectedMenu: "Danh sách chờ khám",
      ),
      body: receptionistState.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIÊU ĐỀ & NÚT LỌC NGÀY CHUYÊN NGHIỆP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hàng đợi khám bệnh',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${allWaitingAppointments.length} bệnh nhân đã check-in trong ngày',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                      
                      // NÚT CHỌN NGÀY LỌC DATA (BẤM VÀO ĐỂ TEST)
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: receptionistState.selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: kPrimaryColor, // Màu chủ đạo của lịch chọn
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          
                          if (picked != null && picked != receptionistState.selectedDate) {
                            // Cập nhật ngày mới vào state và kích hoạt gọi API fetch data tự động
                            // ref.read(receptionistProvider.notifier).updateSelectedDate(picked);
                            ref.read(receptionistProvider.notifier).fetchAppointments(picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 16, color: kPrimaryColor),
                        label: Text(
                          "Ngày: ${DateFormat('dd/MM/yyyy').format(receptionistState.selectedDate)}",
                          style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: kBorderColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Thanh tìm kiếm hoạt động real-time
                  SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên / SĐT / Mã lịch hẹn...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kPrimaryColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hiển thị danh sách thẻ hoặc thông báo trống
                  Expanded(
                    child: filteredWaitingList.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty 
                                  ? 'Không có bệnh nhân nào đang đợi khám trong ngày này.' 
                                  : 'Không tìm thấy bệnh nhân phù hợp.',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 16, 
                              runSpacing: 16, 
                              children: filteredWaitingList.map((appointment) => _buildPatientCard(context, appointment)).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientCard(BuildContext context, dynamic appointment) {
    const statusColor = Color(0xFF2563EB); 
    const statusBgColor = Color(0xFFEFF6FF);

    return Container(
      width: 380, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.patientName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mã: #${appointment.id.toUpperCase()} • Giờ hẹn: ${appointment.time}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ĐÃ CHECK-IN",
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),
                    _infoRow(Icons.medical_services_outlined, 'Bác sĩ', 'BS. ${appointment.doctorName}'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.badge_outlined, 'Chuyên khoa', appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone_outlined, 'SĐT bệnh nhân', appointment.phone),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text('$title: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF334155)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}