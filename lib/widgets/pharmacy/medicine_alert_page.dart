import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../services/api_inventory.dart';
import '../../services/api_medicine.dart';
import '../../widgets/pharmacy/inventory_detail_dialog.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';

class MedicineAlertPage extends StatefulWidget {
  const MedicineAlertPage({super.key});

  @override
  State<MedicineAlertPage> createState() => _MedicineAlertPageState();
}

class _MedicineAlertPageState extends State<MedicineAlertPage> {
  // ================= HỆ MÀU THƯƠNG HIỆU PHARMACARE =================
  static const Color kHeaderBlue = Color(0xFF3EA6E9);
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kDangerRed = Color(0xFFEF4444);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  late Future<List<Map<String, dynamic>>> _alertInventoryFuture;
  String _searchQuery = '';
  String _filterType = 'ALL'; // ALL, CRITICAL (Hết/Dưới sàn), WARNING (Sắp chạm sàn)

  @override
  void initState() {
    super.initState();
    _refreshAlertData();
  }

  void _refreshAlertData() {
    setState(() {
      _alertInventoryFuture = _fetchAndFilterAlertData();
    });
  }

  // Hàm tải dữ liệu song song và lọc các thuốc cần chú ý theo logic cấu hình
  Future<List<Map<String, dynamic>>> _fetchAndFilterAlertData() async {
    final futures = await Future.wait([
      ApiInventory.getInventories(),
      ApiMedicine.getAllMedicines(),
    ]);

    List<InventoryModel> allInventories = futures[0] as List<InventoryModel>;
    dynamic rawMedicines = futures[1];

    // Tạo Map tra cứu danh mục thuốc gốc
    Map<String, dynamic> medicineMap = {};
    if (rawMedicines != null) {
      for (var med in rawMedicines) {
        final String medId = med.id ?? med.idObj ?? '';
        if (medId.isNotEmpty) {
          medicineMap[medId] = med;
        }
      }
    }

    List<Map<String, dynamic>> alertList = [];

    for (var inv in allInventories) {
      final String targetMedId = inv.medicineId.toString();
      dynamic originalMedicine = medicineMap[targetMedId];

      int dynamicMinStock = originalMedicine != null ? (originalMedicine.minStock ?? 0) : inv.minStock;
      String dynamicUnit = originalMedicine != null ? (originalMedicine.unit ?? 'đơn vị') : 'đơn vị';

      inv.minStock = dynamicMinStock;

      // 🟢 ÁP DỤNG ĐÚNG LOGIC CẢNH BÁO: Tồn thực tế < Mức sàn + 5
      if (inv.currentQuantity < (dynamicMinStock + 5)) {
        bool isCritical = inv.currentQuantity <= dynamicMinStock;
        
        alertList.add({
          'inventory': inv,
          'unit': dynamicUnit,
          'minStock': dynamicMinStock,
          'isCritical': isCritical, // true: Dưới sàn nguy hiểm, false: Cảnh báo sớm
        });
      }
    }

    return alertList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const PharmaCaseDrawer(selectedMenu: "Tổng quan"), // Giữ menu tổng quan hoặc tùy biến
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danh Sách Thuốc Cần Chú Ý', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Hệ thống cảnh báo định mức tồn kho thông minh', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshAlertData,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _alertInventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('💥 Lỗi tải nhật ký cảnh báo: ${snapshot.error}', style: const TextStyle(color: kDangerRed)));
          }

          final allAlerts = snapshot.data ?? [];

          // 1. Phân loại bộ lọc tab dữ liệu
          final filteredByTab = allAlerts.where((item) {
            if (_filterType == 'CRITICAL') return item['isCritical'] == true;
            if (_filterType == 'WARNING') return item['isCritical'] == false;
            return true;
          }).toList();

          // 2. Phân loại theo ô tìm kiếm chữ thường
          final finalRecords = filteredByTab.where((item) {
            final InventoryModel inv = item['inventory'] as InventoryModel;
            final query = _searchQuery.toLowerCase();
            return inv.medicineName.toLowerCase().contains(query) ||
                   inv.batchNumber.toLowerCase().contains(query);
          }).toList();

          // Tính toán số lượng huy hiệu (Badge) cho các bộ lọc điều hướng
          int criticalCount = allAlerts.where((e) => e['isCritical'] == true).length;
          int warningCount = allAlerts.where((e) => e['isCritical'] == false).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 1200, // Chuẩn độ rộng giao diện quản trị PharmaCare
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(allAlerts.length),
                    const SizedBox(height: 24),

                    // Khối thanh bộ lọc & Tìm kiếm dữ liệu log
                    _buildFilterAndSearchRow(criticalCount, warningCount),
                    const SizedBox(height: 20),

                    // Bảng log chi tiết các loại thuốc có vấn đề định mức
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: _buildAlertTable(finalRecords),
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

  Widget _buildPageHeader(int totalAlerts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhật ký Cảnh báo Định mức', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 4),
            Text('Phát hiện và liệt kê tự động các mặt hàng nằm trong vùng rủi ro thiếu hụt hàng hóa.', style: const TextStyle(fontSize: 14, color: kTextMuted)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
          label: const Text('Quay lại Tổng Quan', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: kHeaderBlue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )
      ],
    );
  }

  Widget _buildFilterAndSearchRow(int critical, int warning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nhóm nút Tab bộ lọc trạng thái rủi ro
        Row(
          children: [
            _buildFilterTabButton('ALL', 'Tất cả rủi ro', critical + warning, Colors.blue),
            const SizedBox(width: 12),
            _buildFilterTabButton('CRITICAL', '⚠️ Dưới mức sàn', critical, kDangerRed),
            const SizedBox(width: 12),
            _buildFilterTabButton('WARNING', '⏳ Sắp chạm sàn (+5)', warning, kWarningOrange),
          ],
        ),
        // Ô tìm kiếm nhanh thuốc trong danh sách nguy cơ
        Container(
          height: 40,
          width: 320,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderColor)),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
              hintText: 'Tìm thuốc cần nhập kho...',
              hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabButton(String type, String label, int count, Color activeColor) {
    bool isSelected = _filterType == type;
    return InkWell(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : kBorderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : kTextDark, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? activeColor : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(color: isSelected ? Colors.white : kTextMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTable(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('🎉 Tuyệt vời! Không tìm thấy thuốc nào khớp với điều kiện cảnh báo lọc.', style: TextStyle(color: kTextMuted, fontSize: 14))),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      dataRowMaxHeight: 65,
      horizontalMargin: 24,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Tên thuốc / Biệt dược', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Số lô', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Mức tồn kho hiện tại', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Hạn mức sàn (minStock)', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Hạn sử dụng', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Mức độ cảnh báo', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('Hành động yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
        DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: records.map((item) {
        final InventoryModel inv = item['inventory'] as InventoryModel;
        final String unit = item['unit'] as String;
        final int minStock = item['minStock'] as int;
        final bool isCritical = item['isCritical'] as bool;

        String expiryStr = inv.expiryDate != null 
            ? "${inv.expiryDate!.day.toString().padLeft(2, '0')}/${inv.expiryDate!.month.toString().padLeft(2, '0')}/${inv.expiryDate!.year}"
            : "N/A";

        return DataRow(cells: [
          DataCell(Text(inv.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13))),
          DataCell(Text(inv.batchNumber, style: const TextStyle(fontFamily: 'monospace', color: kTextMuted))),
          // Hiển thị số lượng tồn kèm đơn vị tính động của từng thuốc
          DataCell(Text('${inv.currentQuantity} $unit', style: TextStyle(fontWeight: FontWeight.bold, color: isCritical ? kDangerRed : kWarningOrange, fontSize: 14))),
          DataCell(Text('$minStock $unit', style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark))),
          DataCell(Text(expiryStr, style: const TextStyle(color: kTextDark))),
          // Badge trạng thái phân loại mức rủi ro
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: inv.currentQuantity == 0 ? kDangerRed.withOpacity(0.15) : (isCritical ? kDangerRed.withOpacity(0.1) : kWarningOrange.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(6)
            ),
            child: Text(
              inv.currentQuantity == 0 ? 'Hết sạch hàng' : (isCritical ? 'Dưới định mức sàn' : 'Cảnh báo sớm'),
              style: TextStyle(color: isCritical ? kDangerRed : kWarningOrange, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )),
          // Gợi ý nghiệp vụ quản trị nhà thuốc
          DataCell(Text(
            isCritical ? '🛑 Làm lệnh nhập kho gấp!' : '📦 Lập phiếu dự trù mua hàng',
            style: TextStyle(color: isCritical ? kDangerRed : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
          )),
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
                    'min_stock': minStock,
                    'unit': unit,
                    'group': inv.groupName,
                  }),
                );
              },
            ),
          ),
        ]);
      }).toList(),
    );
  }
}