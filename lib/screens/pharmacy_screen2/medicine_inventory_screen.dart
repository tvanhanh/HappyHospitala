import 'package:flutter/material.dart';
import '../../widgets/pharmacy/inventory_detail_dialog.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';

class MedicineInventoryPage extends StatefulWidget {
  const MedicineInventoryPage({super.key});

  @override
  State<MedicineInventoryPage> createState() => _MedicineInventoryPageState();
}

class _MedicineInventoryPageState extends State<MedicineInventoryPage> {
  // ================= HỆ MÀU THƯƠNG HIỆU PHARMACARE (ĐỒNG BỘ) =================
  static const Color kHeaderBlue = Color(0xFF3EA6E9);
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kDangerRed = Color(0xFFEF4444);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  // Bộ lọc nhóm thuốc & Từ khóa tìm kiếm thuốc
  String _selectedGroupFilter = 'Tất cả nhóm';
  String _searchQuery = '';

  // Danh sách các nhóm thuốc theo yêu cầu của bạn
  final List<String> _medicineGroups = [
    'Tất cả nhóm',
    'Kháng sinh',
    'Giảm đau / Hạ sốt',
    'Tim mạch',
    'Tiêu hóa',
    'Hô hấp',
    'Da liễu',
    'Thần kinh',
    'Nội tiết',
    'Vitamin & Khoáng chất',
    'Khác'
  ];

  // Dữ liệu mock-up Tồn kho chứa đầy đủ thông tin chi tiết
  final List<Map<String, dynamic>> _inventoryRecords = [
    {
      'id': 'AMX500',
      'name': 'Amoxicillin 500mg',
      'brand': 'Vidipha',
      'active_ingredient': 'Amoxicillin',
      'group': 'Kháng sinh',
      'stock': 1200,
      'min_stock': 200,
      'unit': 'Viên',
      'import_price': 1200,
      'export_price': 1800,
      'expiry_date': '2026-08-15',
      'status': 'Còn hàng',
    },
    {
      'id': 'PCM500',
      'name': 'Paracetamol 500mg',
      'brand': 'Hậu Giang',
      'active_ingredient': 'Paracetamol',
      'group': 'Giảm đau / Hạ sốt',
      'stock': 150,
      'min_stock': 300,
      'unit': 'Viên',
      'import_price': 800,
      'export_price': 1200,
      'expiry_date': '2026-12-20',
      'status': 'Sắp hết',
    },
    {
      'id': 'AUG1G',
      'name': 'Augmentin 1g',
      'brand': 'GSK',
      'active_ingredient': 'Amoxicillin + Clavulanate',
      'group': 'Kháng sinh',
      'stock': 0,
      'min_stock': 50,
      'unit': 'Hộp',
      'import_price': 150000,
      'export_price': 185000,
      'expiry_date': '2027-03-10',
      'status': 'Hết hàng',
    },
    {
      'id': 'PANXT',
      'name': 'Panadol Extra',
      'brand': 'Sanofi',
      'active_ingredient': 'Paracetamol + Caffeine',
      'group': 'Giảm đau / Hạ sốt',
      'stock': 500,
      'min_stock': 100,
      'unit': 'Viên',
      'import_price': 1100,
      'export_price': 1500,
      'expiry_date': '2025-11-01',
      'status': 'Hết hạn',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // Đăng ký Drawer hệ thống vào Scaffold
      drawer: const PharmaCaseDrawer(selectedMenu: "Tồn kho"),

      // ================= 1. MENU HEADER HỆ THỐNG =================
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        // Dùng Builder để lấy chuẩn BuildContext gọi lệnh mở Drawer
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Mở thanh Menu Drawer bên trái
              },
            );
          }
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF64B5F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PharmaCare System',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Hệ thống quản lý nhà thuốc thông minh',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text(
                    '4',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF64B5F6),
                    child: Text('DS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dược sĩ', style: TextStyle(color: Colors.white, fontSize: 11)),
                      Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ================= 2. BODY QUẢN LÝ TỒN KHO =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SizedBox(
            width: 1200, // ĐÃ GIỮ NGUYÊN: Form list hiển thị độ rộng 1200 gốc của bạn
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 24),

                _buildKpiSection(),
                const SizedBox(height: 32),

                // KHỐI CONTAINER CHỨA TÌM KIẾM + BỘ LỌC NHÓM VÀ BẢNG TỒN KHO
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh trên cùng: Gộp Ô Tìm Kiếm và Dropdown Nhóm Thuốc nằm cạnh nhau
                      _buildSearchAndFilterRow(),
                      
                      const Divider(color: kBorderColor, height: 1),

                      // Bảng dữ liệu chính hiển thị danh sách tồn kho
                      _buildInventoryTable(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tiêu đề trang
  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý tồn kho',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark),
        ),
        SizedBox(height: 4),
        Text(
          'Theo dõi số lượng và trạng thái thuốc trong kho',
          style: TextStyle(fontSize: 14, color: kTextMuted),
        ),
      ],
    );
  }

  // Khối các thẻ KPI Thống kê (Tổng giá trị, Còn hàng, Sắp hết, Hết hàng, Hết hạn)
  Widget _buildKpiSection() {
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tổng giá trị tồn kho', '9.6 triệu đ', const Color(0xFFEFF6FF), kPrimaryBlue, Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Còn hàng', '6', const Color(0xFFECFDF5), kSuccessGreen, Icons.check_circle_outline)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Sắp hết', '2', const Color(0xFFFFFBEB), kWarningOrange, Icons.error_outline_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Hết hàng', '1', const Color(0xFFFEF2F2), kDangerRed, Icons.cancel_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Hết hạn', '1', const Color(0xFFF1F5F9), kTextDark, Icons.hourglass_disabled_outlined)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: kTextMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: textColor, size: 20),
          )
        ],
      ),
    );
  }

  // Giao diện Thanh tìm kiếm và Dropdown danh mục nhóm thuốc kế bên nhau
  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 1. Ô tìm kiếm tên thuốc, hoạt chất, mã thuốc
          Container(
            height: 40,
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                hintText: 'Tìm mã thuốc, tên, hoạt chất...',
                hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Bộ lọc Dropdown chọn Nhóm thuốc
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGroupFilter,
                icon: const Icon(Icons.keyboard_arrow_down, color: kTextDark, size: 20),
                style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500, fontSize: 13),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedGroupFilter = newValue);
                  }
                },
                items: _medicineGroups.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bảng dữ liệu quản lý tồn kho thuốc
  Widget _buildInventoryTable() {
    // Logic bộ lọc kép: Nhóm thuốc & từ khóa tìm kiếm
    final filteredRecords = _inventoryRecords.where((record) {
      final matchesGroup = _selectedGroupFilter == 'Tất cả nhóm' || record['group'] == _selectedGroupFilter;
      final matchesSearch = record['id'].toLowerCase().contains(_searchQuery) ||
                            record['name'].toLowerCase().contains(_searchQuery) ||
                            record['active_ingredient'].toLowerCase().contains(_searchQuery);
      return matchesGroup && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị số lượng thuốc tìm thấy
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            '${filteredRecords.length} / ${_inventoryRecords.length} thuốc',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 14),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowMaxHeight: 65,
            horizontalMargin: 24,
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Mã thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Tên thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Hoạt chất', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Nhóm', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Tồn tối thiểu', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Giá nhập', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Giá bán', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Hạn dùng', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredRecords.map((record) {
              String formatMoney(int val) => val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              
              return DataRow(cells: [
                DataCell(Text(record['id'], style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryBlue))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13)),
                    Text(record['brand'], style: const TextStyle(color: kTextMuted, fontSize: 11)),
                  ],
                )),
                DataCell(Text(record['active_ingredient'], style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13))),
                DataCell(Text(record['group'])),
                DataCell(Text('${record['stock']} ${record['unit']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${record['min_stock']} ${record['unit']}', style: const TextStyle(color: kTextMuted))),
                DataCell(Text('${formatMoney(record['import_price'])} đ')),
                DataCell(Text('${formatMoney(record['export_price'])} đ', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(record['expiry_date'])),
                DataCell(_buildStatusBadge(record['status'])),
                // ICON CON MẮT GỌI POPUP CHI TIẾT TỒN KHO
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: kTextMuted, size: 18),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => InventoryDetailDialog(data: record),
                      );
                    },
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color text;
    if (status == 'Còn hàng') {
      bg = const Color(0xFFDCFCE7); text = const Color(0xFF166534);
    } else if (status == 'Sắp hết') {
      bg = const Color(0xFFFEF3C7); text = const Color(0xFF92400E);
    } else if (status == 'Hết hàng') {
      bg = const Color(0xFFFEF2F2); text = const Color(0xFF991B1B);
    } else {
      bg = const Color(0xFFF1F5F9); text = const Color(0xFF334155); // Hết hạn
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}