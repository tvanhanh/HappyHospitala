import 'package:flutter/material.dart';
import '../../widgets/pharmacase_drawer.dart';
import '../../widgets/add_medicine_dialog.dart';

class MedicineStockScreen extends StatefulWidget {
  const MedicineStockScreen({super.key});

  @override
  State<MedicineStockScreen> createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  // Thống nhất bảng màu thương hiệu
  static const Color kPrimaryBlue = Color(0xFF3EA6E9); 
  static const Color kButtonBlue = Color(0xFF38BDF8);  
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0); 

  // Mock Data dựa chuẩn xác theo bảng dữ liệu trong ảnh của bạn
  final List<Map<String, dynamic>> _medicines = [
    {
      'id': 'M001',
      'name': 'Paracetamol 500mg',
      'category': 'Thuốc giảm đau',
      'quantity': 450,
      'price': '500đ',
      'batch': 'PC2024001',
      'expiry': '2026-12-31',
      'status': 'Còn hàng',
    },
    {
      'id': 'M002',
      'name': 'Amoxicillin 250mg',
      'category': 'Kháng sinh',
      'quantity': 30,
      'price': '2.500đ',
      'batch': 'DHG2024002',
      'expiry': '2026-08-15',
      'status': 'Sắp hết',
    },
    {
      'id': 'M003',
      'name': 'Vitamin C 1000mg',
      'category': 'Vitamin',
      'quantity': 0,
      'price': '1.500đ',
      'batch': 'TP2024003',
      'expiry': '2027-03-20',
      'status': 'Hết hàng',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      // ================= APPBAR ĐỒNG BỘ HỆ THỐNG =================
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
      drawer: const PharmaCaseDrawer(selectedMenu: "Quản lý kho thuốc"),
      
      // ================= THÂN TRANG QUẢN LÝ KHO =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DÒNG TIÊU ĐỀ TRÊN CÙNG & CÁC NÚT THAO TÁC NẰM NGANG
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý kho thuốc',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tổng số: 7 loại thuốc • Tổng giá trị kho: 1.355.500đ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                // Cặp nút bấm: Xuất Excel & Thêm thuốc mới
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 16, color: kPrimaryBlue),
                      label: const Text('Xuất Excel', style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        side: const BorderSide(color: kPrimaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                       context: context,
                       barrierDismissible: true, // Bấm ra ngoài rìa để đóng tap
                       builder: (BuildContext context) {
                       return const AddMedicineDialog();
                        },
                       );
                      },
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Thêm thuốc mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // PHẦN KHUNG TRẮNG CHỨA BỘ LỌC VÀ BẢNG SẢN PHẨM
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THANH BỘ LỌC (FILTER BAR)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Ô tìm kiếm
                        SizedBox(
                          width: 320,
                          height: 44,
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                              hintText: 'Tìm kiếm theo tên, mã thuốc...',
                              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Dropdown Tất cả trạng thái
                        _buildFilterDropdown('Tất cả trạng thái'),
                        const SizedBox(width: 16),
                        // Dropdown Tất cả danh mục
                        _buildFilterDropdown('Tất cả danh mục'),
                      ],
                    ),
                  ),

                  // 2. BẢNG DỮ LIỆU ĐƯỢC CHIA VẠCH NGANG (DATA TABLE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),   // Mã thuốc
                        1: FlexColumnWidth(2.5), // Tên thuốc
                        2: FlexColumnWidth(1.5), // Danh mục
                        3: FlexColumnWidth(1.2), // Số lượng
                        4: FlexColumnWidth(1),   // Giá
                        5: FlexColumnWidth(1.5), // Lô hàng
                        6: FlexColumnWidth(1.5), // Hạn dùng
                        7: FlexColumnWidth(1.3), // Trạng thái
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Hàng Tiêu đề bảng (Header)
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: kBorderColor, width: 1.5)),
                          ),
                          children: [
                            _buildHeaderCell('Mã thuốc'),
                            _buildHeaderCell('Tên thuốc'),
                            _buildHeaderCell('Danh mục'),
                            _buildHeaderCell('Số lượng'),
                            _buildHeaderCell('Giá'),
                            _buildHeaderCell('Lô hàng'),
                            _buildHeaderCell('Hạn dùng'),
                            _buildHeaderCell('Trạng thái'),
                          ],
                        ),
                        // Vòng lặp map danh sách dữ liệu ra các hàng
                        ..._medicines.map((med) => TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: kBorderColor, width: 1)),
                          ),
                          children: [
                            // Mã thuốc dạng tag xám nhỏ
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: UnconstrainedBox(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                  child: Text(med['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                                ),
                              ),
                            ),
                            // Tên thuốc đi kèm Icon tròn màu xanh
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                  child: const Icon(Icons.local_hospital, color: kPrimaryBlue, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(med['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                              ],
                            ),
                            Text(med['category'], style: const TextStyle(color: Color(0xFF334155), fontSize: 14)),
                            // Số lượng đổi màu cảnh báo theo giá trị thực
                            _buildQuantityCell(med['quantity']),
                            Text(med['price'], style: const TextStyle(color: Color(0xFF334155), fontSize: 14)),
                            Text(med['batch'], style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                            // Hạn dùng đi kèm biểu tượng lịch nhỏ
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black38),
                                const SizedBox(width: 6),
                                Text(med['expiry'], style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
                              ],
                            ),
                            // Tag trạng thái bọc bo góc nhiều màu sắc
                            _buildStatusBadge(med['status']),
                          ],
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng ô tiêu đề cột phẳng
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
      ),
    );
  }

  // Widget vẽ nút Dropdown lọc nhanh
  Widget _buildFilterDropdown(String text) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  // Widget xử lý màu chữ cho cột số lượng
  Widget _buildQuantityCell(int qty) {
    Color textColor = const Color(0xFF10B981); // Xanh lá nếu nhiều hàng
    if (qty == 0) {
      textColor = const Color(0xFFEF4444); // Đỏ nếu hết sạch
    } else if (qty <= 30) {
      textColor = const Color(0xFFF59E0B); // Cam nếu sắp hết
    }
    return Text(
      '$qty viên',
      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  // Widget vẽ Kén nhãn trạng thái (Badge)
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Còn hàng':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        break;
      case 'Sắp hết':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'Hết hàng':
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        break;
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
        child: Text(
          status,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}