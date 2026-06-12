import 'dart:convert'; 
import 'dart:io';      
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../../../models/medicine_model.dart'; 
import '../../../services/api_medicine.dart';   
import '../../../services/api_supplier.dart'; 
import '../../../services/api_categoryOfMedicine.dart'; 
import 'package:flutter/foundation.dart'; // Đã có kIsWeb
import 'dart:typed_data'; // Đã có Uint8List

class AddMedicineDialog extends StatefulWidget {
  final VoidCallback onRefresh; 

  const AddMedicineDialog({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kButtonBlue = Color(0xFF38BDF8);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true; 

  List<dynamic> _categories = [];
  List<dynamic> _suppliers = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();      
  final TextEditingController _minStockController = TextEditingController();    
  final TextEditingController _descController = TextEditingController();

  XFile? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImageBytes; // Biến lưu trữ byte dữ liệu ảnh cho Web
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String _selectedUnit = 'Viên';
  String _selectedStatus = 'active';

  final List<String> _units = ['Viên', 'Vỉ', 'Hộp', 'Chai', 'Ống', 'Gói'];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final supplierData = await ApiSupplier.getAllSuppliers();
      final categoryData = await ApiCategoryOfMedicine.getAllCategories(); 

      setState(() {
        _suppliers = supplierData;
        _categories = categoryData;
        _isLoading = false; 
      });
    } catch (e) {
      print("💥 Lỗi tự fetch dữ liệu trong Dialog: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        // 🟢 Đọc byte ảnh bắt buộc dùng cho nền tảng Web
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      print("💥 Lỗi chọn hình ảnh: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _manufacturerController.dispose();
    _priceController.dispose();    
    _minStockController.dispose(); 
    _descController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedSupplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn đầy đủ Danh mục và Nhà cung cấp!'), backgroundColor: Colors.orange),
        );
        return;
      }

      final double parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int parsedMinStock = int.tryParse(_minStockController.text.trim()) ?? 10;

      String? finalImageValue;
      if (_selectedImageFile != null) {
        // Cách 1: Gửi đường dẫn ảnh tạm thời trong máy (Dành cho Mobile/Desktop)
        // Lưu ý: Nếu chạy trên Web, path sẽ là một blob URL. Nếu API của bạn nhận Base64, hãy dùng cách 2.
        finalImageValue = _selectedImageFile!.path; 
        
        // Cách 2: Nếu API yêu cầu chuỗi Base64 (Khuyên dùng khi làm việc đa nền tảng có Web)
        // final bytes = await _selectedImageFile!.readAsBytes();
        // finalImageValue = "data:image/png;base64,${base64Encode(bytes)}";
      }

      final newMedicine = MedicineModel(
        medicineCode: '',
        medicineName: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId!,
        dosage: _dosageController.text.trim(),
        unit: _selectedUnit,
        manufacturer: _manufacturerController.text.trim(),
        sellingPrice: parsedPrice,
        minStock: parsedMinStock,
        imageUrl: finalImageValue, 
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        status: _selectedStatus,
      );

      setState(() => _isLoading = true);
      final result = await ApiMedicine.createMedicine(newMedicine);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result != null) {
        widget.onRefresh(); 
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Đã thêm thuốc '${result.medicineName}' thành công!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Thêm thuốc mới thất bại!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 840,
        color: Colors.white,
        child: _isLoading 
          ? const Padding(
              padding: EdgeInsets.all(80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kPrimaryBlue),
                  SizedBox(height: 16),
                  Text("Đang tải dữ liệu danh mục & đối tác...", style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER =================
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                          child: const Icon(Icons.medication_rounded, color: kPrimaryBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thêm thuốc mới vào hệ thống', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                              SizedBox(height: 4),
                              Text('Dữ liệu phân loại phân hệ được đồng bộ tự động từ cơ sở dữ liệu gốc', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: kBorderColor, height: 1),

                  // ================= BODY FORM =================
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Tên thuốc *', 
                            hint: 'Nhập tên biệt dược...',
                            validator: (v) => v!.trim().isEmpty ? 'Tên thuốc không được để trống' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _dosageController,
                                  label: 'Hàm lượng *', 
                                  hint: 'Ví dụ: 500mg...',
                                  validator: (v) => v!.trim().isEmpty ? 'Hàm lượng không được để trống' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildStaticDropdownField(
                                  label: 'Đơn vị tính *',
                                  value: _selectedUnit,
                                  items: _units,
                                  onChanged: (v) => setState(() => _selectedUnit = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _priceController,
                                  label: 'Giá bán (VNĐ) *', 
                                  hint: 'Ví dụ: 150000',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                  validator: (v) => v!.trim().isEmpty ? 'Giá bán không được để trống' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildTextField(
                                  controller: _minStockController,
                                  label: 'Mức tồn tối thiểu cảnh báo *', 
                                  hint: 'Ví dụ: 10',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                  validator: (v) => v!.trim().isEmpty ? 'Tồn kho cảnh báo không được để trống' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDynamicDropdownField(
                                  label: 'Danh mục *',
                                  hint: 'Chọn nhóm danh mục thuốc',
                                  value: _selectedCategoryId,
                                  items: _categories.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item.id?.toString() ?? item.sId?.toString(),
                                      child: Text(item.categoryname?.toString() ?? 'Không tên'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDynamicDropdownField(
                                  label: 'Nhà cung cấp *',
                                  hint: 'Chọn đối tác phân phối',
                                  value: _selectedSupplierId,
                                  items: _suppliers.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item.id?.toString() ?? item.sId?.toString(),
                                      child: Text(item.supplierName?.toString() ?? item.name?.toString() ?? 'Không tên'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _selectedSupplierId = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _manufacturerController,
                                  label: 'Nhà sản xuất *', 
                                  hint: 'Ví dụ: Dược Hậu Giang...',
                                  validator: (v) => v!.trim().isEmpty ? 'Nhà sản xuất không được để trống' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildStaticDropdownField(
                                  label: 'Trạng thái hoạt động *',
                                  value: _selectedStatus,
                                  items: const ['active', 'inactive'],
                                  itemLabels: const {'active': 'Đang kinh doanh (Active)', 'inactive': 'Tạm dừng (Inactive)'},
                                  onChanged: (v) => setState(() => _selectedStatus = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 🟢 ĐÃ CẬP NHẬT: Giao diện chọn ảnh đa nền tảng
                          _buildImagePickerField(),
                          const SizedBox(height: 20),

                          _buildTextField(
                            controller: _descController,
                            label: 'Mô tả thêm về thuốc', 
                            hint: 'Nhập công dụng chính hoặc ghi chú lưu trữ...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: kBorderColor, height: 1),

                  // ================= FOOTER =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy', style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Thêm vào kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  
  Widget _buildImagePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh sản phẩm',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF8FAFC),
            ),
            child: _selectedImageFile != null
                ? Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: kIsWeb // 🟢 ĐIỀU KIỆN WEB RÕ RÀNG
                              ? Image.memory(
                                  _webImageBytes!, // Nếu là Web thì vẽ từ Bytes dữ liệu
                                  width: 140,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImageFile!.path), // Nếu là Mobile thì đọc từ File path cục bộ
                                  width: 140,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedImageFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Bấm vào đây để chọn ảnh khác',
                                style: TextStyle(fontSize: 12, color: kPrimaryBlue),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => setState(() {
                          _selectedImageFile = null;
                          _webImageBytes = null; // Reset sạch cả bytes khi xóa ảnh
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: kPrimaryBlue, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Tải ảnh lên từ thiết bị',
                        style: TextStyle(color: kTextDark, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Hỗ trợ định dạng JPG, PNG',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? hint, 
    int maxLines = 1, 
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: controller, 
      maxLines: maxLines, 
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13), hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  Widget _buildDynamicDropdownField({required String label, required String hint, required String? value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(color: Colors.black26, fontSize: 13)),
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13), floatingLabelBehavior: FloatingLabelBehavior.always, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5)),
      ),
      items: items, onChanged: onChanged,
    );
  }

  Widget _buildStaticDropdownField({required String label, required String value, required List<String> items, Map<String, String>? itemLabels, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value, isExpanded: true, style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13), floatingLabelBehavior: FloatingLabelBehavior.always, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5)),
      ),
      items: items.map((String val) => DropdownMenuItem<String>(value: val, child: Text(itemLabels != null ? itemLabels[val]! : val))).toList(),
      onChanged: onChanged,
    );
  }
}