import 'package:flutter/material.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';
import '../../services/api_supplier.dart';
import '../../models/category_model.dart';
import '../../services/api_medicine.dart';
import '../../models/medicine_model.dart';
import '../../services/api_categoryOfMedicine.dart';
import '../../services/config.dart';
import '../../widgets/add_medicine_dialog.dart';

class MedicineStockScreen extends StatefulWidget {
  const MedicineStockScreen({super.key});

  @override
  State<MedicineStockScreen> createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  static const Color kPrimaryBlue = Color(0xFF3EA6E9); 
  static const Color kButtonBlue = Color(0xFF38BDF8);  
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0); 

  static const String kBaseUrl = baseUrl;

  // Dữ liệu gốc từ API
  List<MedicineModel> _allMedicines = [];
List<CategoryModel> _categories = [];
  bool _isLoading = false;

  // Các biến phục vụ bộ lọc (Filter & Search)
  String _searchQuery = "";
  String _selectedStatus = "Tất cả trạng thái";
  String _selectedCategoryId = "Tất cả danh mục";

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMedicines(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicines() async {
    setState(() => _isLoading = true);
    try {
      final medicines = await ApiMedicine.getAllMedicines();
      final categoryData = await ApiCategoryOfMedicine.getAllCategories();  
      setState(() {
        _allMedicines = medicines; 
        // 🟢 ĐÃ SỬA: Cast chuẩn kiểu dữ liệu từ API sang List<CategoryModel>
        _categories = List<CategoryModel>.from(categoryData);
      });
    } catch (e) {
      print("💥 Lỗi khi tải danh sách thuốc: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // BỘ LỌC LOGIC THÔNG MINH
  List<MedicineModel> get _filteredMedicines {
    return _allMedicines.where((medicine) {
      // 1. Lọc theo từ khóa tìm kiếm
      final matchesSearch = medicine.medicineName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            medicine.medicineCode.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Lọc theo trạng thái kinh doanh
      bool matchesStatus = true;
      if (_selectedStatus == "Đang bán") {
        matchesStatus = medicine.status == 'active';
      } else if (_selectedStatus == "Tạm dừng") {
        matchesStatus = medicine.status == 'inactive';
      }

      // 3. Lọc theo danh mục thuốc
      bool matchesCategory = true;
      if (_selectedCategoryId != "Tất cả danh mục") {
        matchesCategory = medicine.categoryId == _selectedCategoryId;
      }

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayMedicines = _filteredMedicines;

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
      drawer: const PharmaCaseDrawer(selectedMenu: "Quản lý kho thuốc"),
      
      // 🟢 ĐÃ SỬA: Bọc bằng Scrollbar để hiển thị giao diện Web/Tablets mượt mà hơn
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
                        'Quản lý kho thuốc',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tìm thấy: ${displayMedicines.length} / ${_allMedicines.length} loại thuốc trong hệ thống',
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
                        onPressed: () {
                          showDialog(
                            context: context,
                            // 🟢 ĐÃ SỬA: Sử dụng barrierDismissible tránh lỗi đóng dialog đột ngột gây tràn
                            barrierDismissible: false,
                            builder: (context) => AddMedicineDialog(
                              onRefresh: () {
                                _fetchMedicines(); 
                              },
                            ),
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
  
              // ================= BẢNG HIỂN THỊ DỮ LIỆU THUỐC =================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. THANH BỘ LỌC SEARCH BAR & DROPDOWNS
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 320,
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
                                hintText: 'Tìm kiếm theo tên, mã thuốc...',
                                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          _buildStatusDropdown(),
                          const SizedBox(width: 16),
                          
                          _buildCategoryDropdown(),
                        ],
                      ),
                    ),
  
                    // 2. PHẦN HIỂN THỊ DANH SÁCH CHÍNH
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(60.0),
                              child: CircularProgressIndicator(color: kPrimaryBlue),
                            ),
                          )
                        : displayMedicines.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(60.0),
                                  child: Text('Không tìm thấy dữ liệu thuốc phù hợp với bộ lọc!', style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.5), 
                                    1: FlexColumnWidth(1.0), 
                                    2: FlexColumnWidth(2.5), 
                                    3: FlexColumnWidth(1.8), 
                                    4: FlexColumnWidth(0.8), 
                                    5: FlexColumnWidth(1.2), 
                                    6: FlexColumnWidth(1.2), 
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: kBorderColor, width: 1.5)),
                                      ),
                                      children: [
                                        _buildHeaderCell('Mã thuốc'),
                                        _buildHeaderCell('Hình ảnh'),
                                        _buildHeaderCell('Tên thuốc'),
                                        _buildHeaderCell('Tên phân loại'), // 🟢 ĐÃ SỬA: Đổi tên cột thành Tên phân loại công tâm
                                        _buildHeaderCell('Đơn vị'),
                                        _buildHeaderCell('Giá bán'),
                                        _buildHeaderCell('Trạng thái'),
                                      ],
                                    ),
                                    ...displayMedicines.map((med) => TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: kBorderColor, width: 1)),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: UnconstrainedBox(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                              child: Text(
                                                med.medicineCode.isNotEmpty ? med.medicineCode : 'Chưa có mã',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              color: const Color(0xFFF8FAFC),
                                              child: (med.imageUrl != null && med.imageUrl!.isNotEmpty)
    ? Image.network(
  (() {
    final rawUrl = med.imageUrl!;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    try {
      final baseUri = Uri.parse(kBaseUrl);
      final fullUri = baseUri.resolve(rawUrl);
      return fullUri.toString();
    } catch (e) {
      print("💥 Lỗi parse URL: $e");
      return ''; 
    }
  })(),
  fit: BoxFit.cover,
  headers: const {
          "Access-Control-Allow-Origin": "*",
        },
  errorBuilder: (context, error, stackTrace) {
    print("💥 Lỗi hiển thị ảnh ($error) tại URL: ${med.imageUrl}");
    return const Icon(Icons.image_not_supported, color: Colors.black26);
  },
)
                                                  : const Icon(Icons.medication, color: kPrimaryBlue, size: 24),
                                            ),
                                          ),
                                        ),
  
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(med.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                            const SizedBox(height: 2),
                                            Text(med.dosage, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                          ],
                                        ),
  
                                        // 🟢 CỘT 4 ĐÃ SỬA CHỮA: Dò tìm đối tượng từ danh sách và dùng dấu chấm . thay vì ngoặc vuông ['']
                                        Builder(
                                          builder: (context) {
                                            // Tìm kiếm phần tử danh mục có id khớp với id danh mục của thuốc
                                          final foundCats = _categories.where((cat) => cat.id.toString() == med.categoryId);
                                            final catName = foundCats.isNotEmpty ? foundCats.first.categoryname : 'Chưa phân loại';
                                            return Text(
                                              catName, // Gọi chuẩn qua dấu chấm thuộc tính
                                              style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                                            );
                                          },
                                        ),
  
                                        Text(med.unit, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
  
                                        Text(
                                          '${med.sellingPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')} đ',
                                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
  
                                        _buildStatusBadge(med.status),
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
          items: <String>['Tất cả trạng thái', 'Đang bán', 'Tạm dừng']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    List<DropdownMenuItem<String>> menuItems = [
      const DropdownMenuItem(value: "Tất cả danh mục", child: Text("Tất cả danh mục")),
    ];

    // 🟢 ĐÃ SỬA CHỮA: Sử dụng dấu chấm . thay vì gọi chuỗi ngoặc vuông để tránh crash NoSuchMethodError
    for (var cat in _categories) {
      if (cat.id != null && cat.categoryname != null) {
        menuItems.add(DropdownMenuItem(
          value: cat.id.toString(),
          child: Text(cat.categoryname.toString()),
        ));
      }
    }

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
          value: _selectedCategoryId,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedCategoryId = newValue);
            }
          },
          items: menuItems,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String textLabel;

    if (status == 'active') {
      bgColor = const Color(0xFFDCFCE7); 
      textColor = const Color(0xFF15803D); 
      textLabel = 'Đang bán';
    } else {
      bgColor = const Color(0xFFFEE2E2); 
      textColor = const Color(0xFFB91C1C); 
      textLabel = 'Tạm dừng';
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
        child: Text(
          textLabel,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}