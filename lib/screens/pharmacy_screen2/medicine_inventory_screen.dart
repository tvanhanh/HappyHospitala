import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../services/api_inventory.dart'; 
import '../../services/api_medicine.dart'; // 🟢 Đảm bảo import file chứa hàm ApiMedicine.getAllMedicines()
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

  // Thay đổi kiểu dữ liệu để lưu trữ cả đối tượng lô hàng và đơn vị tính, minStock từ thuốc gốc
  late Future<List<Map<String, dynamic>>> _combinedInventoryFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshInventoryData();
  }

  void _refreshInventoryData() {
    setState(() {
      _combinedInventoryFuture = _fetchAndCombineData();
    });
  }

  // 🟢 Hàm mới: Gọi song song 2 API và trộn dữ liệu danh mục thuốc gốc vào lô hàng kho
  Future<List<Map<String, dynamic>>> _fetchAndCombineData() async {
    final futures = await Future.wait([
      ApiInventory.getInventories(),
      ApiMedicine.getAllMedicines(),
    ]);

    List<InventoryModel> allInventories = futures[0] as List<InventoryModel>;
    dynamic rawMedicines = futures[1];

    // Chuyển mảng thuốc gốc thành Map tra cứu nhanh O(1) theo mã ID thuốc
    Map<String, dynamic> medicineMap = {};
    if (rawMedicines != null) {
      for (var med in rawMedicines) {
        final String medId = med.id ?? med.idObj ?? '';
        if (medId.isNotEmpty) {
          medicineMap[medId] = med;
        }
      }
    }

    // Tiến hành ánh xạ và bổ sung thuộc tính động
    return allInventories.map((inv) {
      final String targetMedId = inv.medicineId.toString();
      dynamic originalMedicine = medicineMap[targetMedId];

      // Đọc minStock và đơn vị tính (unit) động từ cấu trúc danh mục thuốc của bạn
      int dynamicMinStock = originalMedicine != null ? (originalMedicine.minStock ?? 0) : inv.minStock;
      String dynamicUnit = originalMedicine != null ? (originalMedicine.unit ?? 'đơn vị') : 'đơn vị';

      // Gán đồng bộ minStock vào thực thể inventory hiện tại
      inv.minStock = dynamicMinStock;

      return {
        'inventory': inv,
        'unit': dynamicUnit,
        'minStock': dynamicMinStock,
      };
    }).toList();
  }

  // 🟢 ĐÃ SỬA: Hàm tính toán trạng thái động dựa trên cấu hình minStock của TỪNG loại thuốc
  String _calculateStatus(InventoryModel item, int minStock) {
    if (item.status == 'inactive' || item.status == 'expired') return 'Hết hạn';
    if (item.currentQuantity == 0) return 'Hết hàng';
    
    // Kiểm tra hạn sử dụng hệ thống thực tế (Năm 2026)
    if (item.expiryDate != null && item.expiryDate!.isBefore(DateTime.now())) {
      return 'Hết hạn';
    }

    // LOGIC THEO YÊU CẦU: Nếu số tồn kho < mức sàn tối thiểu + 5 thì cảnh báo "Sắp hết"
    if (item.currentQuantity < (minStock + 5)) {
      return 'Sắp hết';
    }
    
    return 'Còn hàng';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const PharmaCaseDrawer(selectedMenu: "Tồn kho"),

      // ================= 1. MENU HEADER HỆ THỐNG =================
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF64B5F6), shape: BoxShape.circle),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshInventoryData,
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ================= 2. BODY QUẢN LÝ TỒN KHO THỰC TẾ =================
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _combinedInventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('💥 Lỗi tải dữ liệu kho: ${snapshot.error}', style: const TextStyle(color: kDangerRed)));
          }

          final allRecords = snapshot.data ?? [];
          
          // Lọc dữ liệu theo ô tìm kiếm động (Mã thuốc, Tên thuốc hoặc Số lô)
          final filteredRecords = allRecords.where((item) {
            final InventoryModel inv = item['inventory'] as InventoryModel;
            final query = _searchQuery.toLowerCase();
            return inv.medicineName.toLowerCase().contains(query) ||
                   inv.medicineId.toLowerCase().contains(query) ||
                   inv.batchNumber.toLowerCase().contains(query);
          }).toList();

          // Tính toán các chỉ số KPI động từ danh sách đã liên kết thuốc gốc
          int totalActive = allRecords.where((e) => _calculateStatus(e['inventory'], e['minStock']) == 'Còn hàng').length;
          int totalLow = allRecords.where((e) => _calculateStatus(e['inventory'], e['minStock']) == 'Sắp hết').length;
          int totalOut = allRecords.where((e) => _calculateStatus(e['inventory'], e['minStock']) == 'Hết hàng').length;
          int totalExpired = allRecords.where((e) => _calculateStatus(e['inventory'], e['minStock']) == 'Hết hạn').length;
          
          double totalValue = allRecords.fold(0, (sum, item) {
            final InventoryModel inv = item['inventory'] as InventoryModel;
            return sum + (inv.currentQuantity * inv.importPrice);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 1200, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 24),

                    _buildKpiSection(totalValue, totalActive, totalLow, totalOut, totalExpired),
                    const SizedBox(height: 32),

                    // KHỐI CONTAINER CHỨA TÌM KIẾM VÀ BẢNG DỮ LIỆU THỰC TẾ
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
                          _buildSearchRow(),
                          const Divider(color: kBorderColor, height: 1),
                          _buildInventoryTable(filteredRecords, allRecords.length),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quản lý tồn kho', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark)),
        SizedBox(height: 4),
        Text('Theo dõi số lượng, số lô và hạn dùng thực tế dựa trên định mức tối thiểu của từng loại thuốc', style: TextStyle(fontSize: 14, color: kTextMuted)),
      ],
    );
  }

  Widget _buildKpiSection(double totalValue, int active, int low, int out, int expired) {
    String formatMoney(double val) {
      if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)} triệu đ';
      return '${val.toStringAsFixed(0)} đ';
    }

    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tổng giá trị tồn kho', formatMoney(totalValue), const Color(0xFFEFF6FF), kPrimaryBlue, Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Còn hàng (Lô)', '$active', const Color(0xFFECFDF5), kSuccessGreen, Icons.check_circle_outline)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Sắp hết (< sàn + 5)', '$low', const Color(0xFFFFFBEB), kWarningOrange, Icons.error_outline_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Hết hàng', '$out', const Color(0xFFFEF2F2), kDangerRed, Icons.cancel_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildKpiCard('Cận hạn/Hết hạn', '$expired', const Color(0xFFF1F5F9), kTextDark, Icons.hourglass_disabled_outlined)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
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

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 380,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderColor)),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                hintText: 'Tìm theo tên thuốc, mã thuốc, số lô...',
                hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(List<Map<String, dynamic>> records, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Hiển thị ${records.length} / $totalCount lô thuốc trong kho',
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
              DataColumn(label: Text('Mã liên kết', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Tên thuốc / Biệt dược', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Số lô (Batch)', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Tồn hiện tại', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Số lượng nhập', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Giá nhập kho', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Hạn dùng (Expiry)', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
              DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: records.map((item) {
              final InventoryModel inv = item['inventory'] as InventoryModel;
              final String unit = item['unit'] as String;
              final int minStock = item['minStock'] as int;

              String formatMoney(double val) => val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              
              String expiryStr = inv.expiryDate != null 
                  ? "${inv.expiryDate!.day.toString().padLeft(2, '0')}/${inv.expiryDate!.month.toString().padLeft(2, '0')}/${inv.expiryDate!.year}"
                  : "N/A";

              // Tính toán trạng thái động theo định mức của chính nó
              String currentStatus = _calculateStatus(inv, minStock);

              return DataRow(cells: [
                DataCell(Text(inv.medicineId.substring(0, 8.clamp(0, inv.medicineId.length)) + '...', style: const TextStyle(color: kTextMuted, fontSize: 12))),
                DataCell(Text(inv.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text(inv.batchNumber, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark, fontFamily: 'monospace'))
                )),
                // Hiển thị số lượng kèm đơn vị tính động của thuốc (Ví dụ: 15 Hộp, 120 Viên)
                DataCell(Text('${inv.currentQuantity} $unit', style: TextStyle(fontWeight: FontWeight.bold, color: currentStatus == 'Sắp hết' ? kWarningOrange : Colors.blue))),
                DataCell(Text('${inv.originalQuantity} $unit', style: const TextStyle(color: kTextMuted))),
                DataCell(Text('${formatMoney(inv.importPrice)} đ')),
                DataCell(Text(expiryStr, style: TextStyle(color: currentStatus == 'Hết hạn' ? kDangerRed : kTextDark, fontWeight: currentStatus == 'Hết hạn' ? FontWeight.bold : FontWeight.normal))),
                DataCell(_buildStatusBadge(currentStatus)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: kTextMuted, size: 18),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => InventoryDetailDialog(data: {
                          'id': inv.id,
                          'medicineId': inv.medicineId,
                          'name': inv.medicineName,
                          'batchNumber': inv.batchNumber,
                          'stock': inv.currentQuantity,
                          'originalQuantity': inv.originalQuantity,
                          'import_price': inv.importPrice,
                          'expiry_date': expiryStr,
                          'importReceiptId': inv.importReceiptId,
                          'status': inv.status,
                          'manufacturer': inv.manufacturer,
                          'selling_price': inv.exportPrice,
                          'min_stock': minStock, // Truyền minStock thực tế đã map
                          'unit': unit,          // Truyền đơn vị tính thực tế đã map
                          'group': inv.groupName,
                        }),
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
      bg = const Color(0xFFE2E8F0); text = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}