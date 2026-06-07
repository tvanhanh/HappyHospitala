import 'package:flutter/material.dart';
import '../../widgets/pharmacase_drawer.dart';
import '../../widgets/dispense_dialog/dispense_medicine_dialog.dart';
class PendingPrescriptionsScreen extends StatelessWidget {
  const PendingPrescriptionsScreen({super.key});

  // Hệ màu thương hiệu PharmaCare đồng bộ
  static const Color kPrimaryBlue = Color(0xFF3EA6E9); 
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kUrgentBg = Color(0xFFFEF9C3); // Vàng nhạt cho đơn khẩn
  static const Color kUrgentBorder = Color(0xFFEAB308); // Viền vàng cam đậm cho đơn khẩn
  static const Color kUrgentTag = Color(0xFFEA580C); // Màu cam cháy chữ "Khẩn"

  @override
  Widget build(BuildContext context) {
    // Cấu trúc dữ liệu thực tế do bạn cung cấp
    final List<Map<String, dynamic>> prescriptions = [
      {
        'code': 'RX001',
        'date': '2024-06-03',
        'isUrgent': true,
        'status': 'Chờ xử lý',
        'patient': 'Nguyễn Văn An',
        'doctor': 'BS. Trần Thị Hoa',
        'medicines': [
          {'name': 'Paracetamol 500mg', 'usage': '1 viên x 3 lần/ngày', 'qty': 30},
          {'name': 'Vitamin C 1000mg', 'usage': '1 viên x 1 lần/ngày', 'qty': 10},
        ]
      },
      {
        'code': 'RX002',
        'date': '2024-06-03',
        'isUrgent': false,
        'status': 'Chờ xử lý',
        'patient': 'Trần Thị Bình',
        'doctor': 'BS. Lê Văn Nam',
        'medicines': [
          {'name': 'Amoxicillin 250mg', 'usage': '1 viên x 2 lần/ngày', 'qty': 20},
          {'name': 'Omeprazole 20mg', 'usage': '1 viên x 1 lần/ngày', 'qty': 14},
        ]
      },
      {
        'code': 'RX003',
        'date': '2024-06-02',
        'isUrgent': false,
        'status': 'Đã cấp',
        'patient': 'Lê Văn Cường',
        'doctor': 'BS. Nguyễn Văn Đức',
        'medicines': [
          {'name': 'Metformin 500mg', 'usage': '1 viên x 2 lần/ngày', 'qty': 60},
        ]
      },
      {
        'code': 'RX004',
        'date': '2024-06-03',
        'isUrgent': true,
        'status': 'Chờ xử lý',
        'patient': 'Phạm Thị Dung',
        'doctor': 'BS. Trần Thị Hoa',
        'medicines': [
          {'name': 'Ibuprofen 400mg', 'usage': '1 viên x 3 lần/ngày khi đau', 'qty': 20},
        ]
      },
    ];

    // Lọc danh sách chỉ lấy các đơn ở trạng thái Chờ xử lý để hiển thị chính
    final pendingList = prescriptions.where((p) => p['status'] == 'Chờ xử lý').toList();

    return Scaffold(
      backgroundColor: kBgColor,
      // ================= APPBAR CHUẨN ĐỒNG BỘ =================
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PharmaCare System", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text("Hệ thống quản lý nhà thuốc thông minh", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white, size: 22), onPressed: () {}),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Text('DS', style: TextStyle(fontSize: 11, color: kPrimaryBlue, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const PharmaCaseDrawer(selectedMenu: "Đơn thuốc chờ"),
      
      // ================= THÂN TRANG DANH SÁCH ĐƠN THUỐC CHỜ =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Thống kê số lượng
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn thuốc chờ xử lý',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
                ),
                SizedBox(height: 6),
                Text(
                  '3 đơn thuốc đang chờ • 2 đơn khẩn',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ĐÃ SỬA: Thay thế Wrap bằng GridView để khoá cứng layout 3 cột / hàng
            GridView.builder(
              shrinkWrap: true, // Cho phép lồng trong SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Để cuộn mượt theo toàn trang
              itemCount: pendingList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // ÉP ĐÚNG 3 CÁI TRÊN MỘT HÀNG
                crossAxisSpacing: 24, // Khoảng cách chiều ngang giữa các thẻ
                mainAxisSpacing: 24,    // Khoảng cách chiều dọc giữa các dòng
                mainAxisExtent: 380,   // Chiều cao cố định của mỗi thẻ đơn thuốc để không bị vỡ layout
              ),
              itemBuilder: (context, index) {
                return _buildPrescriptionDetailCard(context, pendingList[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= BIỂU DIỄN THẺ CHI TIẾT ĐƠN THUỐC CẤP CAO =================
  Widget _buildPrescriptionDetailCard(BuildContext context, Map<String, dynamic> pres) {
    final bool isUrgent = pres['isUrgent'];

    return Container(
      // ĐÃ SỬA: Xoá thuộc tính width cố định cũ để thẻ tự giãn tràn đều theo tỷ lệ cột của GridView
      decoration: BoxDecoration(
        color: isUrgent ? kUrgentBg.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? kUrgentBorder : kBorderColor,
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Phần Đầu Thẻ (Mã đơn, Ngày, Tag trạng thái Khẩn)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      pres['code'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pres['date'],
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kUrgentTag, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 12),
                        SizedBox(width: 2),
                        Text('Khẩn', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
              ],
            ),
          ),
          
          const Divider(color: kBorderColor, height: 1),

          // 2. Phần Thông Tin Hành Chính (Bệnh nhân & Bác sĩ)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👤 ', style: TextStyle(fontSize: 14)),
                    const Text('Bệnh nhân: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Text(
                        pres['patient'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('👨‍⚕️ ', style: TextStyle(fontSize: 14)),
                    const Text('Bác sĩ kê đơn: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Text(
                        pres['doctor'], 
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Khung Nền Trắng Trong Suốt Hiển Thị Toàn Bộ Danh Sách Thuốc Kê Đơn
          Expanded( // ĐÃ SỬA: Dùng Expanded để khung danh sách thuốc tự co giãn lấp đầy không gian trống, đẩy nút bấm xuống đáy đồng đều giữa tất cả các thẻ
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor.withOpacity(0.5)),
              ),
              child: SingleChildScrollView( // Đề phòng danh sách thuốc quá dài không bị tràn khung
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💊', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'Danh sách thuốc (${(pres['medicines'] as List).length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(pres['medicines'] as List).map((med) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 2),
                                  Text(med['usage'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                'SL: ${med['qty']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 4. Thanh Nút Thao Tác Đáy Thẻ
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                      context: context,
                     barrierDismissible: false, // Ép buộc thực hiện đủ quy trình không bấm ra ngoài đóng bừa
                     builder: (BuildContext context) {
                      return DispenseMedicineDialog(prescription: pres); // Gửi gói đơn thuốc sang để map thông tin
                      },
                   );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUrgent ? kUrgentTag : kPrimaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'CẤP PHÁT THUỐC',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}