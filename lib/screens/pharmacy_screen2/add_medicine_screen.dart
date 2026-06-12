// import 'package:flutter/material.dart';
// import '../../../models/medicine_model.dart';

// // --- PALETTE MÀU ĐỒNG BỘ HỆ THỐNG ---
// const Color kPrimaryColor = Color(0xFF1565C0); 
// const Color kBackgroundColor = Color(0xFFF5F7FA);

// class AddMedicinePage extends StatefulWidget {
//   const AddMedicinePage({Key? key}) : super(key: key);

//   @override
//   State<AddMedicinePage> createState() => _AddMedicinePageState();
// }

// class _AddMedicinePageState extends State<AddMedicinePage> {
//   final _formKey = GlobalKey<FormState>();

//   // Controllers nhận dữ liệu text
//   final nameCtrl = TextEditingController();
//   final dosageCtrl = TextEditingController();
//   final manufacturerCtrl = TextEditingController();
//   final descriptionCtrl = TextEditingController();

//   // Biến lưu giá trị Dropdown (Cần map ID thực tế từ List Category/Supplier của bạn)
//   String? selectedCategoryId;
//   String? selectedSupplierId;
//   String selectedUnit = 'Viên';
//   String selectedStatus = 'active';

//   // Dữ liệu mẫu giả lập (Sau này bạn sẽ fetch từ API về điền vào đây)
//   final List<Map<String, String>> mockCategories = [
//     {'id': 'cat_01', 'name': 'Thuốc kháng sinh'},
//     {'id': 'cat_02', 'name': 'Thuốc giảm đau, hạ sốt'},
//     {'id': 'cat_03', 'name': 'Vitamin & Thực phẩm chức năng'},
//   ];

//   final List<Map<String, String>> mockSuppliers = [
//     {'id': 'sup_01', 'name': 'Dược phẩm CPC1'},
//     {'id': 'sup_02', 'name': 'Công ty cổ phần dược Hậu Giang'},
//   ];

//   final List<String> unitList = ['Viên', 'Vỉ', 'Hộp', 'Chai', 'Ống', 'Gói'];

//   bool _isLoading = false;

//   void _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       if (selectedCategoryId == null || selectedSupplierId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Vui lòng chọn Danh mục và Nhà cung cấp!'), backgroundColor: Colors.orange)
//         );
//         return;
//       }

//       final newMedicine = MedicineModel(
//         medicineName: nameCtrl.text.trim(),
//         categoryId: selectedCategoryId!,
//         supplierId: selectedSupplierId!,
//         dosage: dosageCtrl.text.trim(),
//         unit: selectedUnit,
//         manufacturer: manufacturerCtrl.text.trim(),
//         description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
//         status: selectedStatus,
//       );

//       setState(() => _isLoading = true);
      
//       // TODO: Gọi API thêm thuốc ở đây
//       // final result = await ApiMedicine.createMedicine(newMedicine);
//       await Future.delayed(const Duration(seconds: 1)); // Giả lập chờ API

//       setState(() => _isLoading = false);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("🎉 Đã thêm thuốc '${newMedicine.medicineName}' thành công!"), backgroundColor: Colors.green)
//         );
//         Navigator.pop(context); // Quay lại trang trước
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBackgroundColor,
//       appBar: AppBar(
//         title: const Text('Nhập Thuốc Mới', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//         backgroundColor: kPrimaryColor,
//         centerTitle: true,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _isLoading 
//         ? const Center(child: CircularProgressIndicator())
//         : SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // --- CỤM 1: THÔNG TIN CƠ BẢN ---
//                   _buildSectionTitle('Thông tin thuốc'),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: nameCtrl,
//                     decoration: _inputDecoration('Tên thuốc *', Icons.medication),
//                     validator: (v) => v!.trim().isEmpty ? 'Không được để trống tên thuốc' : null,
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: dosageCtrl,
//                           decoration: _inputDecoration('Hàm lượng * (VD: 500mg)', Icons.biotech),
//                           validator: (v) => v!.trim().isEmpty ? 'Nhập hàm lượng' : null,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           value: selectedUnit,
//                           decoration: _inputDecoration('Đơn vị tính', Icons.layers),
//                           items: unitList.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
//                           onChanged: (v) => setState(() => selectedUnit = v!),
//                         ),
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
//                   // --- CỤM 2: PHÂN LOẠI & ĐỐI TÁC ---
//                   _buildSectionTitle('Phân loại & Nguồn cung'),
//                   const SizedBox(height: 10),
//                   DropdownButtonFormField<String>(
//                     value: selectedCategoryId,
//                     hint: const Text('Chọn danh mục thuốc *'),
//                     decoration: _inputDecoration('Danh mục thuốc', Icons.category),
//                     items: mockCategories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!))).toList(),
//                     onChanged: (v) => setState(() => selectedCategoryId = v),
//                   ),
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<String>(
//                     value: selectedSupplierId,
//                     hint: const Text('Chọn nhà cung cấp *'),
//                     decoration: _inputDecoration('Nhà cung cấp', Icons.business),
//                     items: mockSuppliers.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']!))).toList(),
//                     onChanged: (v) => setState(() => selectedSupplierId = v),
//                   ),

//                   const SizedBox(height: 20),
//                   // --- CỤM 3: THÔNG TIN CHI TIẾT ---
//                   _buildSectionTitle('Chi tiết sản xuất'),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: manufacturerCtrl,
//                     decoration: _inputDecoration('Nhà sản xuất *', Icons.factory_outlined),
//                     validator: (v) => v!.trim().isEmpty ? 'Không được để trống nhà sản xuất' : null,
//                   ),
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<String>(
//                     value: selectedStatus,
//                     decoration: _inputDecoration('Trạng thái hoạt động', Icons.toggle_on),
//                     items: const [
//                       DropdownMenuItem(value: 'active', child: Text('Đang hoạt động (Kinh doanh)')),
//                       DropdownMenuItem(value: 'inactive', child: Text('Ngừng hoạt động (Tạm dừng)')),
//                     ],
//                     onChanged: (v) => setState(() => selectedStatus = v!),
//                   ),
//                   const SizedBox(height: 12),
//                   TextFormField(
//                     controller: descriptionCtrl,
//                     maxLines: 3,
//                     decoration: _inputDecoration('Mô tả thêm về thuốc', Icons.description_outlined),
//                   ),

//                   const SizedBox(height: 30),
//                   // --- NÚT LƯU DỮ LIỆU ---
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: kPrimaryColor,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 2,
//                       ),
//                       onPressed: _submitForm,
//                       icon: const Icon(Icons.save, color: Colors.white),
//                       label: const Text('Lưu thông tin thuốc', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor, letterSpacing: 0.5),
//     );
//   }

//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.6), size: 20),
//       labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//       floatingLabelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
//       isDense: true, 
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
//       errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1)),
//       focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
//       contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
//       filled: true,
//       fillColor: Colors.grey.shade50,
//     );
//   }
// }