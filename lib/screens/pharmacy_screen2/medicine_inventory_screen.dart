import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../services/api_inventory.dart'; 
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

  late Future<List<InventoryModel>> _inventoryFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshInventoryData();
  }

  void _refreshInventoryData() {
    setState(() {
      _inventoryFuture = ApiInventory.getInventories();
    });
  }

  // Hàm tính toán trạng thái động dựa trên số lượng tồn kho thực tế và hạn sử dụng (Năm 2026)
  String _calculateStatus(InventoryModel item) {
    if (item.status == 'inactive' || item.status == 'expired') return 'Hết hạn';
    if (item.currentQuantity == 0) return 'Hết hàng';
    if (item.currentQuantity < 50) return 'Sắp hết'; // Ngưỡng cảnh báo sắp hết hàng lẻ
    
    // Kiểm tra hạn sử dụng giả định với mốc thời gian hệ thống hiện tại
    if (item.expiryDate != null && item.expiryDate!.isBefore(DateTime.now())) {
      return 'Hết hạn';
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
      body: FutureBuilder<List<InventoryModel>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('💥 Lỗi tải dữ liệu kho: ${snapshot.error}', style: const TextStyle(color: kDangerRed)));
          }

          final allRecords = snapshot.data ?? [];
          
          // Lọc dữ liệu theo ô tìm kiếm (Mã thuốc, Tên thuốc hoặc Số lô)
          final filteredRecords = allRecords.where((item) {
            final query = _searchQuery.toLowerCase();
            return item.medicineName.toLowerCase().contains(query) ||
                   item.medicineId.toLowerCase().contains(query) ||
                   item.batchNumber.toLowerCase().contains(query);
          }).toList();

          // Tính toán các chỉ số KPI động từ DB thực tế
          int totalActive = allRecords.where((e) => _calculateStatus(e) == 'Còn hàng').length;
          int totalLow = allRecords.where((e) => _calculateStatus(e) == 'Sắp hết').length;
          int totalOut = allRecords.where((e) => _calculateStatus(e) == 'Hết hàng').length;
          int totalExpired = allRecords.where((e) => _calculateStatus(e) == 'Hết hạn').length;
          double totalValue = allRecords.fold(0, (sum, item) => sum + (item.currentQuantity * item.importPrice));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 1200, // ĐỒNG BỘ: Độ rộng chuẩn khung quản trị của bạn
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
        Text('Theo dõi số lượng, số lô và hạn dùng thực tế từ cơ sở dữ liệu', style: TextStyle(fontSize: 14, color: kTextMuted)),
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
        Expanded(child: _buildKpiCard('Sắp hết', '$low', const Color(0xFFFFFBEB), kWarningOrange, Icons.error_outline_outlined)),
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

  Widget _buildInventoryTable(List<InventoryModel> records, int totalCount) {
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
              String formatMoney(double val) => val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              
              String expiryStr = item.expiryDate != null 
                  ? "${item.expiryDate!.day.toString().padLeft(2, '0')}/${item.expiryDate!.month.toString().padLeft(2, '0')}/${item.expiryDate!.year}"
                  : "N/A";

              String currentStatus = _calculateStatus(item);

              return DataRow(cells: [
                DataCell(Text(item.medicineId.substring(0, 8.clamp(0, item.medicineId.length)) + '...',style: const TextStyle(color: kTextMuted, fontSize: 12))),
                DataCell(Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text(item.batchNumber, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark, fontFamily: 'monospace'))
                )),
                DataCell(Text('${item.currentQuantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                DataCell(Text('${item.originalQuantity}', style: const TextStyle(color: kTextMuted))),
                DataCell(Text('${formatMoney(item.importPrice)} đ')),
                DataCell(Text(expiryStr, style: TextStyle(color: currentStatus == 'Hết hạn' ? kDangerRed : kTextDark, fontWeight: currentStatus == 'Hết hạn' ? FontWeight.bold : FontWeight.normal))),
                DataCell(_buildStatusBadge(currentStatus)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: kTextMuted, size: 18),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => InventoryDetailDialog(data: {
                         'id': item.id,
        'medicineId': item.medicineId,
        'name': item.medicineName,
        'batchNumber': item.batchNumber,
        'stock': item.currentQuantity,
        'originalQuantity': item.originalQuantity,
        'import_price': item.importPrice,
        'expiry_date': expiryStr,
        'importReceiptId': item.importReceiptId,
        'status': item.status,
        'manufacturer': item.manufacturer,
        'selling_price': item.exportPrice,
        'min_stock': item.minStock,
        'group': item.groupName,
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
      bg = const Color(0xFFE2E8F0); text = const Color(0xFF475569); // Hết hạn / Khóa
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}