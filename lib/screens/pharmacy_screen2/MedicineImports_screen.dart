import 'package:flutter/material.dart';
import '../../models/import_model.dart';
import '../../widgets/pharmacy/import_detail_dialog.dart';
import '../../widgets/pharmacy/CreateImportDialog.dart';
import '../../services/api_import.dart';
import '../../services/api_supplier.dart';

class MedicineImportsPage extends StatefulWidget {
  const MedicineImportsPage({super.key});

  @override
  State<MedicineImportsPage> createState() => _MedicineImportsPageState();
}

class _MedicineImportsPageState extends State<MedicineImportsPage> {
  // ================= HỆ MÀU THƯƠNG HIỆU PHARMACARE =================
  static const Color kHeaderBlue = Color(0xFF3EA6E9); 
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  // Bộ lọc trạng thái & Từ khóa tìm kiếm
  String _selectedStatusFilter = 'Tất cả trạng thái';
  String _searchQuery = ''; 
  List<ImportModel> _allImports = [];
  List<ImportModel> _filteredImports = [];
  List<dynamic> _suppliers = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải dữ liệu an toàn - Tránh việc một API sập kéo theo cả trang bị trắng dữ liệu
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Gọi dữ liệu phiếu nhập kho trước
      final importData = await ApiImport.fetchImportRecords();
      _allImports = importData ?? [];

      // 2. Gọi dữ liệu nhà cung cấp (bọc try-catch riêng để an toàn)
      try {
        final supplierData = await ApiSupplier.getAllSuppliers();
        _suppliers = supplierData ?? [];
      } catch (supplierError) {
        debugPrint("Lỗi tải API Supplier: $supplierError");
      }

      setState(() {
        _applyFilter(); 
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tổng tại trang ImportPage: $e");
      setState(() => _isLoading = false);
    }
  }

  dynamic _getSupplierValue(dynamic item, String key) {
    if (item == null) return null;
    if (item is Map) return item[key];
    try {
      if (key == 'id') return item.id;
      if (key == 'supplierName') return item.supplierName;
    } catch (_) {}
    return null;
  }

 String _getSupplierNameById(dynamic supplierId) {
   if (supplierId == null) return 'Không rõ';
    if (_suppliers.isEmpty) return 'ID: $supplierId';
    

    for (var s in _suppliers) {
      if (_getSupplierValue(s, 'id').toString() == supplierId.toString()) {
        return _getSupplierValue(s, 'supplierName') ?? 'Nhà cung cấp không tên';
      }
    }

    return 'ID: $supplierId'; 
  }

  void _applyFilter() {
    setState(() {
      _filteredImports = _allImports.where((importRecord) {
        final matchesStatus = _selectedStatusFilter == 'Tất cả trạng thái' || 
                              importRecord.status == _selectedStatusFilter;
        
        final supplierName = _getSupplierNameById(importRecord.supplierId).toLowerCase();

        final matchesSearch = _searchQuery.isEmpty ||
            (importRecord.note?.toLowerCase().contains(_searchQuery) ?? false) ||
            importRecord.supplierId.toString().toLowerCase().contains(_searchQuery) ||
            supplierName.contains(_searchQuery) || 
            importRecord.products.any((p) => p.medicineName.toLowerCase().contains(_searchQuery));

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
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
                const Text('PharmaCare System', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Hệ thống quản lý nhà thuốc thông minh', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
              Positioned(
                top: 12, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 14, backgroundColor: Color(0xFF64B5F6),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: SizedBox(
                    width: 1300, // 🚀 ĐÃ SỬA: Tăng kích thước rộng Form tổng lên 1300 cho thoải mái không gian hiển thị
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: 24),
                        _buildKpiSection(),
                        const SizedBox(height: 32),

                        // KHỐI CONTAINER CHỨA THANH TÌM KIẾM + BỘ LỌC + BẢNG DỮ LIỆU
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorderColor),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 16, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchAndFilterRow(),
                              const Divider(color: kBorderColor, height: 1),
                              _buildImportTable(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập kho thuốc', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark)),
            SizedBox(height: 4),
            Text('Quản lý các phiếu nhập hàng từ nhà cung cấp', style: TextStyle(fontSize: 14, color: kTextMuted)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CreateImportDialog(onRefresh: _loadData),
            );
          },
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('Tạo phiếu nhập', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        )
      ],
    );
  }

  Widget _buildKpiSection() {
    int totalCount = _allImports.length;
    int completedCount = _allImports.where((e) => ((e as dynamic).status ?? 'Hoàn thành') == 'Hoàn thành').length;
    int pendingCount = totalCount - completedCount;

    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tổng phiếu nhập', '$totalCount', const Color(0xFFEFF6FF), kPrimaryBlue)),
        const SizedBox(width: 20),
        Expanded(child: _buildKpiCard('Đã hoàn thành', '$completedCount', const Color(0xFFECFDF5), kSuccessGreen)),
        const SizedBox(width: 20),
        Expanded(child: _buildKpiCard('Chờ duyệt / Khác', '$pendingCount', const Color(0xFFFFFBEB), kWarningOrange)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.receipt_long, color: textColor, size: 24),
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    final statuses = ['Tất cả trạng thái', 'Hoàn thành', 'Đã duyệt', 'Chờ duyệt'];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 40, width: 320, 
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderColor)),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value.trim().toLowerCase();
                _applyFilter(); 
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                hintText: 'Tìm phiếu nhập, thuốc, NCC...',
                hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _selectedStatusFilter = status;
                          _applyFilter(); 
                        }
                      },
                      selectedColor: kPrimaryBlue.withOpacity(0.12),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSelected ? kPrimaryBlue : kTextDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      side: BorderSide(color: isSelected ? kPrimaryBlue : kBorderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTable() {
    if (_filteredImports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: Text('Không tìm thấy dữ liệu phiếu nhập nào.', style: TextStyle(color: kTextMuted))),
      );
    }

    // 🚀 ĐÃ SỬA: Thêm SingleChildScrollView (cuộn ngang) bao bọc ngoài DataTable 
    // Tránh việc vỡ giao diện hệ thống khi cột tên Nhà Cung Cấp hiển thị chuỗi text dài.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1260, // Khóa chiều rộng tối thiểu cho nội dung các cột trong bảng được phân bổ rộng rãi
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMaxHeight: 65,
          horizontalMargin: 24,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('Mặt hàng chính', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('Số lượng loại', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
            DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))), 
          ],
          rows: _filteredImports.map((record) {
            final mainMedicineName = record.products.isNotEmpty ? record.products.first.medicineName : 'Chưa rõ';
            final restCount = record.products.length > 1 ? ' (+${record.products.length - 1})' : '';
            final status = record.status;

            return DataRow(cells: [
              DataCell(
                SizedBox(
                  width: 220, // 🚀 ĐÃ TĂNG: Tên nhà cung cấp được cấp tối đa tới 220px để hiển thị trọn vẹn
                  child: Text(
                    _getSupplierNameById(record.supplierId), 
                    style: const TextStyle(overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                  ),
                ),
              ),
              DataCell(SizedBox(
                width: 200,
                child: Text('$mainMedicineName$restCount', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: kTextDark))
              )),
              DataCell(Text('${record.products.length} loại thuốc')),
              DataCell(Text(
                '${record.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark),
              )),
              DataCell(SizedBox(
                width: 180,
                child: Text(record.note ?? '---', overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextMuted))
              )),
              DataCell(_buildStatusBadge(status)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: kTextMuted, size: 20),
                  onPressed: () {
                    Map<String, dynamic> dialogData = record.toJson();
                    dialogData['supplierName'] = _getSupplierNameById(record.supplierId);
                    showDialog(
                      context: context,
                      builder: (context) => ImportDetailDialog(data: dialogData), 
                    );
                  },
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color text;
    if (status == 'Hoàn thành') {
      bg = const Color(0xFFDCFCE7); text = const Color(0xFF166534);
    } else if (status == 'Đã duyệt') {
      bg = const Color(0xFFE0F2FE); text = const Color(0xFF0369A1);
    } else {
      bg = const Color(0xFFFEF3C7); text = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}