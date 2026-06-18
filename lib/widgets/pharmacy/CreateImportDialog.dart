import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_medicine.dart';
import '../../services/api_supplier.dart';
import '../../models/importMedicine_model.dart';
import '../../services/api_importMedicine.dart';

class CreateImportDialog extends StatefulWidget {
  final VoidCallback? onRefresh;
  const CreateImportDialog({super.key, this.onRefresh});

  @override
  State<CreateImportDialog> createState() => _CreateImportDialogState();
}

class _CreateImportDialogState extends State<CreateImportDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController(); // 🔥 THÊM MỚI: Quản lý giá bán của lô
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _suppliers = [];
  List<dynamic> _medicines = [];

  String? _selectedSupplierId;
  String? _selectedMedicineId;
  DateTime? _selectedExpiryDate;
  dynamic _selectedMedicine;
  String? _currentUserId;
  String? _currentUserName;

  List<ImportItem> _addedItems = [];
  double _billTotalAmount = 0;

  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchDropdownAndUserData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _sellingPriceController.dispose(); // 🔥 Giải phóng bộ nhớ
    _batchController.dispose();
    _expiryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  dynamic _getValue(dynamic item, String key) {
    if (item == null) return null;
    if (item is Map) {
      if (key == 'id') return item['id'] ?? item['_id'];
      return item[key];
    }
    try {
      switch (key) {
        case 'id': return item.id;
        case 'medicineId': return item.medicineId;
        case 'medicineName': return item.medicineName;
        case 'medicineCode': return item.medicineCode;
        case 'supplierName': return item.supplierName;
        case 'currentStock': return item.currentStock;
        case 'unit': return item.unit;
        case 'sellingPrice': return item.sellingPrice; // 🔥 Hỗ trợ lấy giá bán
        case 'importPrice': return item.importPrice;   // 🔥 Hỗ trợ lấy giá nhập
        default: return null;
      }
    } catch (_) { return null; }
  }

  Future<void> _fetchDropdownAndUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId') ?? prefs.getString('_id');
      _currentUserName = prefs.getString('name') ?? 'Nhân viên kho';

      final supplierData = await ApiSupplier.getAllSuppliers();
      final medicineData = await ApiMedicine.getAllMedicines();
      setState(() {
        _suppliers = supplierData ?? [];
        _medicines = medicineData ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addItemToList() {
    if (_selectedMedicineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một mặt hàng thuốc!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0; // 🔥 Đọc giá bán lô từ ô nhập liệu

    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng và đơn giá phải lớn hơn 0!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (sellingPrice < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảnh báo: Giá bán đang thấp hơn giá nhập kho!'), backgroundColor: Colors.amber),
      );
    }

    String detectedName = 'Thuốc không tên';
    if (_selectedMedicine != null) {
      detectedName = _getValue(_selectedMedicine, 'medicineName') ?? 
                     _getValue(_selectedMedicine, 'name') ?? 
                     'Thuốc không tên';
    }

    // 🚀 ĐÃ NÂNG CẤP: Truyền cả sellingPrice (Giá bán riêng của lô) vào Model
    final newItem = ImportItem(
      medicineId: _selectedMedicineId,
      medicineName: detectedName,
      quantity: qty,
      importPrice: price,
      sellingPrice: sellingPrice, // 🔥 Lưu vào model để đẩy lên Backend lưu vào Inventory
      batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      expiryDate: _selectedExpiryDate,
    );

    setState(() {
      _addedItems.add(newItem);
      _billTotalAmount += (qty * price);
      
      // Clear thông tin mặt hàng vừa thêm để sẵn sàng cho thuốc tiếp theo
      _selectedMedicineId = null;
      _selectedMedicine = null;
      _quantityController.clear();
      _priceController.clear();
      _sellingPriceController.clear(); // 🔥 Xóa ô giá bán
      _batchController.clear();
      _expiryController.clear();
      _selectedExpiryDate = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _addedItems[index];
      _billTotalAmount -= (item.quantity * item.importPrice);
      _addedItems.removeAt(index);
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _expiryController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _handleSubmit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Nhà cung cấp!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Tự động gom nếu người dùng đang nhập dở ở ô trên chưa bấm "Gom vào danh sách"
    if (_selectedMedicineId != null && _quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final qty = int.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;

      if (qty > 0 && price > 0) {
        String detectedName = 'Thuốc không tên';
        if (_selectedMedicine != null) {
          detectedName = _getValue(_selectedMedicine, 'medicineName') ?? 
                         _getValue(_selectedMedicine, 'name') ?? 
                         'Thuốc không tên';
        }

        final autoItem = ImportItem(
          medicineId: _selectedMedicineId,
          medicineName: detectedName,
          quantity: qty,
          importPrice: price,
          sellingPrice: sellingPrice, // 🔥 Kèm giá bán tự động gom
          batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
          expiryDate: _selectedExpiryDate,
        );

        _addedItems.add(autoItem);
        _billTotalAmount += (qty * price);
      }
    }

    if (_addedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Danh sách phiếu nhập chưa có thuốc nào!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final importRecord = ImportModel(
      supplierId: _selectedSupplierId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      totalAmount: _billTotalAmount,
      products: _addedItems,
      status: 'Chờ duyệt',
      createdBy: _currentUserName,
    );

    setState(() => _isLoading = true);

    try {
      final result = await ApiImport.createImportRecord(importRecord);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        widget.onRefresh?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Nhập kho lô hàng thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration({required String labelText, String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText, hintText: hintText, suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: kTextMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 1100,
        height: 850, // 🚀 Tăng nhẹ chiều cao để chứa thêm ô nhập liệu cân đối
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.note_add_outlined, color: kPrimaryBlue, size: 28),
                                    SizedBox(width: 12),
                                    Text("Lập phiếu nhập kho đa thuốc", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                                  ],
                                ),
                                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                              ],
                            ),
                            const Divider(height: 32, color: kBorderColor),

                            const Text("1. Thông tin đối tác cung ứng *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryBlue)),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _selectedSupplierId,
                              hint: const Text("-- Chọn nhà cung cấp cố định cho hóa đơn này --", style: TextStyle(fontSize: 14)),
                              decoration: _buildInputDecoration(labelText: "Nhà cung cấp"),
                              items: _suppliers.map<DropdownMenuItem<String>>((s) {
                                final String id = (_getValue(s, 'id') ?? '').toString();
                                return DropdownMenuItem(value: id, child: Text(_getValue(s, 'supplierName') ?? ''));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedSupplierId = val),
                            ),
                            const SizedBox(height: 24),

                            const Text("2. Chọn thuốc & Điền thông tin chi tiết", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryBlue)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedMedicineId,
                                    hint: const Text("Chọn mặt hàng thuốc muốn thêm...", style: TextStyle(fontSize: 14)),
                                    decoration: _buildInputDecoration(labelText: "Tên mặt hàng"),
                                    items: _medicines.map<DropdownMenuItem<String>>((m) {
                                      final String id = (_getValue(m, 'id') ?? '').toString();
                                      final String name = (_getValue(m, 'medicineName') ?? _getValue(m, 'name') ?? 'Không tên');
                                      final String code = (_getValue(m, 'medicineCode') ?? '---');
                                      return DropdownMenuItem(value: id, child: Text("$name ($code)"));
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedMedicineId = val;
                                        _selectedMedicine = null;
                                        
                                        for (var m in _medicines) {
                                          final String dbId = (_getValue(m, 'id') ?? '').toString().trim().toLowerCase();
                                          final String selectedId = (val ?? '').toString().trim().toLowerCase();
                                          if (dbId == selectedId) {
                                            _selectedMedicine = m;
                                            
                                            // 🔥 LOGIC GỢI Ý GIÁ TỰ ĐỘNG KHI CHỌN THUỐC ĐÃ ĐƯỢC THÊM TẠI ĐÂY:
                                            final baseSellingPrice = _getValue(m, 'sellingPrice') ?? _getValue(m, 'exportPrice') ?? 0;
                                            final baseImportPrice = _getValue(m, 'importPrice') ?? 0;
                                            
                                            if (baseSellingPrice > 0) {
                                              _sellingPriceController.text = baseSellingPrice.toStringAsFixed(0);
                                            } else {
                                              _sellingPriceController.clear();
                                            }

                                            if (baseImportPrice > 0) {
                                              _priceController.text = baseImportPrice.toStringAsFixed(0);
                                            } else {
                                              _priceController.clear();
                                            }
                                            break;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // HÀNG 1: SỐ LƯỢNG - GIÁ NHẬP - GIÁ BÁN MỚI
                                  Row(
                                    children: [
                                      Expanded(child: TextFormField(controller: _quantityController, keyboardType: TextInputType.number, decoration: _buildInputDecoration(labelText: "Số lượng nhập"))),
                                      const SizedBox(width: 16),
                                      Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: _buildInputDecoration(labelText: "Đơn giá mua (đ)"))),
                                      const SizedBox(width: 16),
                                      // 🔥 Ô NHẬP LIỆU GIÁ BÁN ĐÃ ĐƯỢC THÊM VÀO GIAO DIỆN (3 CỘT ĐỀU NHAU)
                                      Expanded(child: TextFormField(controller: _sellingPriceController, keyboardType: TextInputType.number, decoration: _buildInputDecoration(labelText: "Giá bán đề xuất lô này (đ)", hintText: "Gợi ý từ hệ thống"))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // HÀNG 2: SỐ LÔ - HẠN SỬ DỤNG
                                  Row(
                                    children: [
                                      Expanded(child: TextFormField(controller: _batchController, decoration: _buildInputDecoration(labelText: "Số lô (Batch No.)"))),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _pickExpiryDate,
                                          child: AbsorbPointer(child: TextFormField(controller: _expiryController, decoration: _buildInputDecoration(labelText: "Hạn sử dụng", suffixIcon: const Icon(Icons.calendar_month, color: kPrimaryBlue)))),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange, 
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                      ),
                                      onPressed: _addItemToList,
                                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                                      label: const Text("Gom vào danh sách", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            const Text("3. Danh sách thuốc chờ đẩy lên hệ thống", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                            const SizedBox(height: 10),
                            _addedItems.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text("Chưa có thuốc nào được gom vào phiếu này.", style: TextStyle(color: kTextMuted, fontStyle: FontStyle.italic))))
                                : Container(
                                    decoration: BoxDecoration(border: Border.all(color: kBorderColor), borderRadius: BorderRadius.circular(12)),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _addedItems.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1, color: kBorderColor),
                                      itemBuilder: (context, index) {
                                        final item = _addedItems[index];
                                        String formatVND(double val) => val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
                                        
                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          title: Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            // 🔥 ĐÃ CẬP NHẬT: Hiển thị song song cả Giá nhập và Giá bán lô trong danh sách hàng đợi
                                            child: Text("SL: ${item.quantity}  |  Mua vào: ${formatVND(item.importPrice)}đ  |  Bán ra: ${formatVND(item.sellingPrice ?? 0)}đ  |  Lô: ${item.batchNumber ?? 'N/A'}"),
                                          ),
                                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22), onPressed: () => _removeItem(index)),
                                        );
                                      },
                                    ),
                                  ),
                            const SizedBox(height: 24),
                            TextFormField(controller: _noteController, decoration: _buildInputDecoration(labelText: "Ghi chú phiếu nhập chung")),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: kBorderColor))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng hóa đơn: ${_billTotalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ", 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: () => Navigator.pop(context), 
                              child: const Text("Hủy", style: TextStyle(color: kTextDark))
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ), 
                              onPressed: _handleSubmit, 
                              child: const Text("Xác nhận nhập kho", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }
}