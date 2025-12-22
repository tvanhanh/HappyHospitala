import 'package:flutter/material.dart';

// --- PALETTE MÀU ĐỒNG BỘ (Xanh Dương chủ đạo) ---
const Color kPrimaryColor =
    Color(0xFF1565C0); // Xanh dương đậm (giống Admin Dashboard)
const Color kPrimaryLight = Color(0xFFE3F2FD); // Xanh nhạt (làm nền nhẹ)
const Color kWarningColor = Color(0xFFFF9800); // Cam (Cảnh báo)
const Color kErrorColor = Color(0xFFE53935); // Đỏ (Nguy hiểm)
const Color kSafeColor = Color(0xFF43A047); // Xanh lá (An toàn)
const Color kBackgroundColor = Color(0xFFF5F7FA);

class MedicineInventory extends StatefulWidget {
  @override
  _MedicineInventoryState createState() => _MedicineInventoryState();
}

class _MedicineInventoryState extends State<MedicineInventory> {
  // Dữ liệu mẫu (Giữ nguyên)
  List<Map<String, dynamic>> inventory = [
    {
      'name': 'Paracetamol 500mg',
      'category': 'Thuốc viên',
      'quantity': 450,
      'max': 500,
      'unit': 'viên',
      'expiry': '12/2026',
      'isLowStock': false,
    },
    {
      'name': 'Amoxicillin 250mg',
      'category': 'Kháng sinh',
      'quantity': 45, // Sắp hết
      'max': 200,
      'unit': 'viên',
      'expiry': '08/2024',
      'isLowStock': true,
    },
    {
      'name': 'Siro Ho Prospan',
      'category': 'Siro',
      'quantity': 80,
      'max': 100,
      'unit': 'chai',
      'expiry': '01/2024',
      'isLowStock': false,
    },
    {
      'name': 'Bông băng y tế',
      'category': 'Vật tư',
      'quantity': 120,
      'max': 150,
      'unit': 'cuộn',
      'expiry': 'N/A',
      'isLowStock': false,
    },
  ];

  String _selectedFilter = 'Tất cả';

  // --- LOGIC LỌC (Giữ nguyên) ---
  List<Map<String, dynamic>> get _filteredList {
    if (_selectedFilter == 'Tất cả') return inventory;
    if (_selectedFilter == 'Sắp hết')
      return inventory.where((i) => i['isLowStock'] == true).toList();
    return inventory.where((i) => i['category'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,

      // --- APP BAR ---
      appBar: AppBar(
        title: Text('Kho Dược Phẩm',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})],
      ),

      body: Column(
        children: [
          // 1. DASHBOARD THỐNG KÊ (ĐÃ SỬA MÀU)
          _buildDashboardStats(),

          // 2. BỘ LỌC
          _buildFilterBar(),

          // 3. DANH SÁCH KHO
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                return _buildMedicineCard(_filteredList[index], index);
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: kPrimaryColor, // Đồng bộ màu nút
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_shopping_cart),
        label: Text("Nhập Kho"),
      ),
    );
  }

  // --- WIDGET CON: THỐNG KÊ (Sửa lại màu nền trắng cho sạch sẽ) ---
  Widget _buildDashboardStats() {
    int lowStockCount = inventory.where((i) => i['isLowStock'] == true).length;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, 25), // Padding dưới lớn hơn xíu để bo góc đẹp
      decoration: BoxDecoration(
        color: kPrimaryColor, // Nền xanh liền mạch với AppBar
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // Khối mờ bên trong
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem("Tổng tồn kho", "695", Icons.inventory_2),
            Container(width: 1, height: 40, color: Colors.white24),
            _buildStatItem(
                "Cảnh báo", "$lowStockCount", Icons.warning_amber_rounded,
                isWarning: true),
            Container(width: 1, height: 40, color: Colors.white24),
            _buildStatItem("Giá trị kho", "\$12k", Icons.attach_money),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {bool isWarning = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon,
                color: isWarning ? kWarningColor : Colors.white, size: 20),
            SizedBox(width: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? kWarningColor : Colors.white)),
          ],
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // --- WIDGET CON: THANH LỌC (Sửa màu Chip) ---
  Widget _buildFilterBar() {
    List<String> filters = [
      'Tất cả',
      'Sắp hết',
      'Thuốc viên',
      'Kháng sinh',
      'Siro',
      'Vật tư'
    ];
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) =>
                  setState(() => _selectedFilter = filter),
              // Màu khi chọn: Xanh đậm, chữ trắng
              selectedColor: kPrimaryColor,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              backgroundColor: Colors.white,
              side: BorderSide(
                  color:
                      isSelected ? Colors.transparent : Colors.grey.shade300),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET CON: CARD THUỐC (Sửa lại màu thanh tiến trình) ---
  Widget _buildMedicineCard(Map<String, dynamic> item, int index) {
    double progress = item['quantity'] / item['max'];
    bool isExpired = item['expiry'].toString().contains('2024');

    // Màu trạng thái dựa trên tình trạng thuốc
    Color statusColor;
    if (item['isLowStock']) {
      statusColor = kWarningColor;
    } else if (isExpired) {
      statusColor = kErrorColor;
    } else {
      statusColor = kSafeColor; // Xanh lá an toàn thay vì blue
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Icon Thuốc (Nền màu nhạt theo trạng thái)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                      item['category'] == 'Vật tư'
                          ? Icons.medical_services_outlined
                          : Icons.medication_rounded,
                      color: statusColor,
                      size: 30),
                ),
                SizedBox(width: 15),

                // 2. Thông tin chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800)),
                      SizedBox(height: 4),
                      Text("HSD: ${item['expiry']}",
                          style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? kErrorColor : Colors.grey)),
                    ],
                  ),
                ),

                // 3. Menu Action
                Icon(Icons.more_vert, color: Colors.grey.shade400),
              ],
            ),

            SizedBox(height: 15),

            // 4. Thanh trạng thái kho
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tồn kho:",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: "${item['quantity']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 14)),
                        TextSpan(
                            text: "/${item['max']} ${item['unit']}",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    color: statusColor, // Màu thanh tiến trình theo trạng thái
                    minHeight: 6,
                  ),
                ),
                if (item['isLowStock'])
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: kWarningColor),
                        SizedBox(width: 4),
                        Text("Sắp hết hàng - Cần nhập thêm",
                            style: TextStyle(
                                fontSize: 11,
                                color: kWarningColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
