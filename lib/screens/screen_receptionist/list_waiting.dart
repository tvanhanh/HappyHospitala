import 'package:flutter/material.dart';
import '../../widgets/receptionist_drawer.dart';

class ListWaitingScreen extends StatelessWidget {
  const ListWaitingScreen({super.key});

  // Hệ màu cao cấp chuẩn Clinic SaaS
  static const Color kPrimaryColor = Color(0xFF0F172A); // Màu tối sang trọng thay cho xanh đậm cổ điển
  static const Color kBackgroundColor = Color(0xFFF8FAFC); 
  static const Color kBorderColor = Color(0xFFE2E8F0);

  final List<Map<String, dynamic>> waitingList = const [
    {
      'name': 'Nguyễn Văn An',
      'age': 35,
      'doctor': 'Trần Thị Hoa',
      'time': '08:30',
      'phone': '0901234567',
      'status': 'Đang chờ',
    },
    {
      'name': 'Trần Thị Bình',
      'age': 28,
      'doctor': 'Lê Văn Nam',
      'time': '09:00',
      'phone': '0902345678',
      'status': 'Đang khám',
    },
    {
      'name': 'Lê Văn Cường',
      'age': 42,
      'doctor': 'Trần Thị Hoa',
      'time': '09:30',
      'phone': '0903456789',
      'status': 'Đang chờ',
    },
    {
      'name': 'Phạm Thị Dung',
      'age': 51,
      'doctor': 'Nguyễn Văn Đức',
      'time': '10:00',
      'phone': '0904567890',
      'status': 'Đang chờ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
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
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Danh sách chờ khám",
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Số lượng
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hàng đợi khám bệnh',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${waitingList.length} bệnh nhân trong danh sách',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Thanh tìm kiếm khít gọn
            SizedBox(
              height: 36,
              child: TextField(
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên / SĐT / Mã bệnh nhân...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F172A))),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // GIẢI PHÁP: Thay thế GridView bằng Wrap chạy cuộn mượt mà
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16, // Khoảng cách ngang giữa các thẻ
                  runSpacing: 16, // Khoảng cách dọc giữa các hàng
                  children: waitingList.map((patient) => _buildPatientCard(context, patient)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    final isWaiting = patient['status'] == 'Đang chờ';
    final statusColor = isWaiting ? const Color(0xFFEA580C) : const Color(0xFF2563EB); // Màu sắc đậm đà hiện đại
    final statusBgColor = isWaiting ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF);

    // CỐ ĐỊNH CHIỀU RỘNG THẺ: Giúp thẻ không bị bẻ rộng xấu xí khi dùng màn hình lớn
    return Container(
      width: 380, // Chiều rộng lý tưởng gọn gàng
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
            // 1. Thanh chỉ thị màu mỏng bo góc khít ở biên trái
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
            ),
            
            // 2. Nội dung chi tiết bên trong thẻ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14), // Padding vừa vặn, không quá trống
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HÀNG 1: TÊN BN VÀ TAG TRẠNG THÁI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient['name'],
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${patient['age']} tuổi • STT: ${patient['time']}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Tag trạng thái nhỏ nhắn, bo góc tinh tế
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            patient['status'].toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),

                    // HÀNG 2: THÔNG TIN BÁC SĨ & SĐT
                    _infoRow(Icons.medical_services_outlined, 'Bác sĩ', 'BS. ${patient['doctor']}'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone_outlined, 'SĐT', patient['phone']),
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