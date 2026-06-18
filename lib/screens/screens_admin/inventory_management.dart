import 'package:flutter/material.dart';
import 'add_category_dialog.dart';
import '../../models/category_model.dart';
import '../../services/api_categoryOfMedicine.dart';
import '../../models/importMedicine_model.dart';
import '../../services/config.dart';
import '../../services/api_importMedicine.dart';
import '../../services/api_supplier.dart';

class MedicineInventory extends StatefulWidget {
  const MedicineInventory({Key? key}) : super(key: key);

  @override
  _MedicineInventoryState createState() => _MedicineInventoryState();
}

class _MedicineInventoryState extends State<MedicineInventory> {
  // --- PALETTE MÀU ĐỒNG BỘ THEO PHARMACARE SYSTEM ---
  static const Color kPrimaryBlue = Color(0xFF1565C0); 
  static const Color kButtonBlue = Color(0xFF38BDF8);  
  static const Color kBgColor = Color(0xFFF5F7FA);     
  static const Color kBorderColor = Color(0xFFE2E8F0); 

  static const String kBaseUrl = baseUrl;
  List<ImportModel> _allImport = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  List<dynamic> _suppliers = []; 

  // Các biến phục vụ bộ lọc (Filter & Search)
  String _searchQuery = "";
  String _selectedStatus = "Tất cả trạng thái";

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Tải dữ liệu từ server
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final importData = await ApiImport.fetchImportRecords();
      // ĐÃ SỬA: Đồng bộ đúng tên biến _allImport
      _allImport = importData ?? [];

      // Khối try-catch riêng cho Supplier đề phòng lỗi API không làm sập giao diện chính
      try {
        final supplierData = await ApiSupplier.getAllSuppliers();
        _suppliers = supplierData ?? [];
      } catch (supplierError) {
        debugPrint("💥 Lỗi tải API Nhà cung cấp tại Inventory: $supplierError");
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("💥 Lỗi tổng tại trang Inventory: $e");
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

  // HÀM XỬ LÝ DUYỆT ĐƠN NHẬP KHO
  Future<void> _approveImportOrder(ImportModel order) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Xác nhận duyệt'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn duyệt đơn nhập kho này không? Dữ liệu thuốc sẽ tự động được cộng vào kho chính.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      setState(() => _isLoading = true);
    
bool isSuccess = await ApiImport.updateStatus(order.id, 'Đã duyệt');
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Duyệt đơn nhập kho thành công!'), backgroundColor: Colors.green),
        );
        _fetchData(); // Reload dữ liệu mới
      } else {
        throw Exception('Phản hồi từ server thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💥 Lỗi khi duyệt đơn: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  } // ĐÃ SỬA: Bổ sung dấu đóng ngoặc nhọn bị thiếu ở đây

  // BỘ LỌC LOGIC ĐƠN NHẬP KHO THÔNG MINH
  List<ImportModel> get _filteredImports {
    return _allImport.where((order) {
      // 1. Lọc theo trạng thái đơn hàng
      bool matchesStatus = _selectedStatus == "Tất cả trạng thái" || order.status == _selectedStatus;

      // 2. Tìm kiếm thông minh theo Tên NCC, ID, Ghi chú, Người tạo, Tên thuốc
      final supplierName = _getSupplierNameById(order.supplierId).toLowerCase();
      final supplierIdStr = order.supplierId?.toString().toLowerCase() ?? '';
      final noteStr = order.note?.toLowerCase() ?? '';
      final creatorStr = order.createdBy?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      bool matchesSearch = query.isEmpty ||
          supplierName.contains(query) ||
          supplierIdStr.contains(query) ||
          noteStr.contains(query) ||
          creatorStr.contains(query) ||
          (order.products != null && order.products.any((p) => (p as dynamic).medicineName.toString().toLowerCase().contains(query)));

      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _showAddCategoryDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddCategoryDialog(primaryColor: kPrimaryBlue);
      }
    );
    _fetchData();
  }

  // HÀM HIỂN THỊ DIALOG CHI TIẾT ĐƠN HÀNG (Nút con mắt)
  void _showOrderDetailsDialog(ImportModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6, // Chiếm 60% màn hình Desktop/Web
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: kPrimaryBlue, size: 28),
                        SizedBox(width: 8),
                        Text('Chi Tiết Chứng Từ Nhập Kho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 24, thickness: 1.2),

                // Thông tin tổng quan đơn hàng
                Wrap(
                  spacing: 40,
                  runSpacing: 12,
                  children: [
                    _buildDetailInfoItem('Nhà cung cấp:', _getSupplierNameById(order.supplierId)),
                    _buildDetailInfoItem('Người lập đơn:', order.createdBy ?? 'Hệ thống'),
                    _buildDetailInfoItem('Trạng thái:', order.status ?? 'Chờ duyệt'),
                    _buildDetailInfoItem('Tổng tiền:', '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')} đ', isBold: true),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailInfoItem('Ghi chú:', order.note ?? 'Không có ghi chú'),
                
                const SizedBox(height: 20),
                const Text('Danh sách sản phẩm nhập:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),

                // Bảng danh sách sản phẩm trong đơn hàng
                Flexible(
                  child: Container(
                    height: 300, // Khống chế chiều cao bảng tránh tràn màn hình
                    decoration: BoxDecoration(border: Border.all(color: kBorderColor), borderRadius: BorderRadius.circular(8)),
                    child: SingleChildScrollView(
                      child: DataTable(
                        // ĐÃ SỬA: Thay thế MaterialStateProperty thành WidgetStateProperty hiện đại hơn
                        headingRowColor: WidgetStateProperty.all(kBgColor),
                        columns: const [
                          DataColumn(label: Text('Tên thuốc / Vật tư', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        ],
                        rows: order.products.map((product) {
                          final double price = (product as dynamic).importPrice ?? 0.0;
                          final int qty = (product as dynamic).quantity ?? 0;
                          return DataRow(cells: [
                            DataCell(Text((product as dynamic).medicineName ?? 'N/A')),
                            DataCell(Text(qty.toString())),
                            DataCell(Text('${price.toStringAsFixed(0)} đ')),
                            DataCell(Text('${(price * qty).toStringAsFixed(0)} đ', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                    child: const Text('Đóng', style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailInfoItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(color: Colors.black54, fontSize: 14),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: isBold ? Colors.redAccent : const Color(0xFF0F172A),
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayImports = _filteredImports;

    return Scaffold(
      backgroundColor: kBgColor,
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
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TIÊU ĐỀ TRÊN CÙNG =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản Lý Nhập Kho',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tìm thấy: ${displayImports.length} / ${_allImport.length} chứng từ nhập kho trong hệ thống',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
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
                        onPressed: () => _showAddCategoryDialog(context),
                        icon: const Icon(Icons.add_box_outlined, size: 18, color: Colors.white),
                        label: const Text('Thêm danh mục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

              // ================= BẢNG HIỂN THỊ DỮ LIỆU ĐƠN NHẬP =================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. THANH BỘ LỌC SEARCH BAR & DROPDOWN STATUS
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 350,
                            height: 44,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = "");
                                        },
                                      )
                                    : null,
                                hintText: 'Tìm theo nhà cung cấp, ghi chú, thuốc...',
                                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildStatusDropdown(),
                        ],
                      ),
                    ),

                    // 2. PHẦN BẢNG DỮ LIỆU CHÍNH ĐỒNG BỘ CHUẨN ĐƠN NHẬP KHO
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(60.0),
                              child: CircularProgressIndicator(color: kPrimaryBlue),
                            ),
                          )
                        : displayImports.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(60.0),
                                  child: Text('Không tìm thấy hóa đơn nhập kho nào phù hợp!', style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2.2), 
                                    1: FlexColumnWidth(1.0), 
                                    2: FlexColumnWidth(1.4), 
                                    3: FlexColumnWidth(1.8), 
                                    4: FlexColumnWidth(1.2), 
                                    5: FlexColumnWidth(1.3), 
                                    6: FlexColumnWidth(1.8), 
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: kBorderColor, width: 1.5)),
                                      ),
                                      children: [
                                        _buildHeaderCell('Nhà cung cấp'),
                                        _buildHeaderCell('Số mặt hàng'),
                                        _buildHeaderCell('Tổng số tiền'), 
                                        _buildHeaderCell('Ghi chú'),
                                        _buildHeaderCell('Người lập'),
                                        _buildHeaderCell('Trạng thái'),
                                        _buildHeaderCell('Thao tác'),
                                      ],
                                    ),
                                    ...displayImports.map((order) => TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: kBorderColor, width: 1)),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: Text(
                                            _getSupplierNameById(order.supplierId),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                        Text('${order.products.length} loại', style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
                                        Text(
                                          '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')} đ',
                                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        Text(order.note ?? '---', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
                                        Text(order.createdBy ?? 'Hệ thống', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                        _buildStatusBadge(order.status),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, color: kPrimaryBlue, size: 20),
                                                tooltip: 'Xem chi tiết đơn',
                                                onPressed: () => _showOrderDetailsDialog(order),
                                              ),
                                              const SizedBox(width: 4),
                                              order.status == 'Chờ duyệt' 
                                                ? ElevatedButton.icon(
                                                    onPressed: () => _approveImportOrder(order),
                                                    icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                                                    label: const Text('Duyệt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      elevation: 0,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                  )
                                                : const Row(
                                                    children: [
                                                      Icon(Icons.verified, color: Colors.blue, size: 16),
                                                      SizedBox(width: 4),
                                                      Text('Đã đóng', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
                                                    ],
                                                  ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )).toList(),
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
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedStatus = newValue);
            }
          },
          items: <String>['Tất cả trạng thái', 'Chờ duyệt', 'Đã duyệt', 'Đã nhập kho']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String textLabel = status;

    if (status == 'Chờ duyệt') {
      bgColor = const Color(0xFFFEF3C7); 
      textColor = const Color(0xFFD97706); 
    } else if (status == 'Đã duyệt' || status == 'Đã nhập kho') {
      bgColor = const Color(0xFFDCFCE7); 
      textColor = const Color(0xFF15803D); 
      textLabel = 'Đã hoàn tất';
    } else {
      bgColor = const Color(0xFFF1F5F9); 
      textColor = const Color(0xFF475569); 
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Text(
          textLabel,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}