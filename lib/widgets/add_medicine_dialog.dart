import 'package:flutter/material.dart';

class AddMedicineDialog extends StatefulWidget {
  const AddMedicineDialog({super.key});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  // Thống nhất hệ màu mockup thiết kế
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kButtonBlue = Color(0xFF38BDF8);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  
  // Các biến lưu trữ giá trị nhập liệu
  String? _selectedCategory;
  final TextEditingController _dateController = TextEditingController();

  // Danh mục mẫu trùng khớp hệ thống
  final List<String> _categories = ['Thuốc giảm đau', 'Kháng sinh', 'Vitamin', 'Thuốc dạ dày'];

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 840, // Độ rộng chuẩn Desktop theo tỉ lệ ảnh mẫu
        color: Colors.white,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= PHẦN TIÊU ĐỀ DIALOG (HEADER) =================
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                      child: const Icon(Icons.local_hospital_rounded, color: kPrimaryBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm thuốc mới vào kho',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nhập đầy đủ thông tin thuốc và lô hàng',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: kBorderColor, height: 1),

              // ================= PHẦN NỘI DUNG NHẬP LIỆU (BODY FORM) =================
              Container(
                constraints: const BoxConstraints(maxHeight: 500), // Giới hạn chiều cao có thanh cuộn
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Hàng 1: Mã thuốc & Mã lô hàng
                      Row(
                        children: [
                          Expanded(child: _buildTextField(label: 'Mã thuốc *', hint: 'Ví dụ: M004')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextField(label: 'Mã lô hàng *', hint: 'Ví dụ: DHG2024002')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Hàng 2: Tên thuốc trải dài full chiều ngang
                      _buildTextField(label: 'Tên thuốc *', hint: 'Nhập tên thương mại hoặc biệt dược...'),
                      const SizedBox(height: 20),

                      // Hàng 3: Danh mục (Dropdown) & Nhà cung cấp
                      Row(
                        children: [
                          Expanded(child: _buildDropdownField(label: 'Danh mục *')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextField(label: 'Nhà cung cấp *', hint: 'Nhập tên công ty dược...')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Hàng 4: Số lượng, Đơn vị, Giá thành
                      Row(
                        children: [
                          Expanded(child: _buildTextField(label: 'Số lượng *', initialValue: '1', isNumber: true)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextField(label: 'Đơn vị *', hint: 'Viên / Hộp / Chai')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextField(label: 'Giá (VNĐ) *', hint: 'Nhập giá', isNumber: true)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Hàng 5: Hạn sử dụng
                      _buildDateField(label: 'Hạn sử dụng *'),
                    ],
                  ),
                ),
              ),
              const Divider(color: kBorderColor, height: 1),

              // ================= PHẦN NÚT ĐIỀU HƯỚNG ĐÁY TRANG (FOOTER) =================
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Thực hiện lưu logic ở đây
                          Navigator.pop(context);
                        }
                      },
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
              )
            ],
          ),
        ),
      ),
    );
  }

  // Khung ô nhập liệu Text cơ bản bo góc
  Widget _buildTextField({required String label, String? hint, String? initialValue, bool isNumber = false}) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always, // Đẩy nhãn lên viền đúng mẫu
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5)),
      ),
    );
  }

  // Khung Dropdown lựa chọn danh mục có viền màu xanh chủ đạo khi tương tác
  Widget _buildDropdownField({required String label}) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      hint: const Text('Chọn danh mục', style: TextStyle(color: Colors.black26, fontSize: 13)),
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kPrimaryBlue, fontSize: 13, fontWeight: FontWeight.w600), // Màu xanh nổi bật
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue)),
      ),
      items: _categories.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) => setState(() => _selectedCategory = newValue),
    );
  }

  // Ô nhập ngày tháng đi kèm Picker lịch
  Widget _buildDateField({required String label}) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        hintText: 'dd/mm/yyyy',
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) {
          setState(() {
            _dateController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
          });
        }
      },
    );
  }
}