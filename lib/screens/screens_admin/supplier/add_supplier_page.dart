import 'package:flutter/material.dart';
import '../../../models/supplier_model.dart';
import '../../../services/api_supplier.dart';

// --- PALETTE MÀU ĐỒNG BỘ HỆ THỐNG ---
const Color kPrimaryColor = Color(0xFF1565C0); 
const Color kBackgroundColor = Color(0xFFF5F7FA);

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({Key? key}) : super(key: key);

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  List<Map<String, dynamic>> suppliers = []; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động gọi tải danh sách nhà cung cấp khi vừa mở màn hình
    _fetchSuppliers();
  }

  // --- 1. HÀM GỌI API LẤY DANH SÁCH (GET LIST) ---
  Future<void> _fetchSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final List<SupplierModel> result = await ApiSupplier.getAllSuppliers();
      setState(() {
        // Chuyển đổi List<SupplierModel> thành List<Map<String, dynamic>> để khớp cấu trúc biến lưu trữ của bạn
        suppliers = result.map((item) => {
          'id': item.id, // Lưu lại ID để phục vụ tác vụ Xóa
          'supplierName': item.supplierName,
          'contactName': item.contactName,
          'phone': item.phone,
          'address': item.address,
          'supplierType': item.supplierType,
          'status': item.status,
          'note': item.note,
        }).toList();
      });
    } catch (e) {
      print("Lỗi khi nạp danh sách: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- HÀM MỞ DIALOG THÊM NHÀ CUNG CẤP ---
  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    String supplierType = 'medicine_local'; 
    String status = 'active'; 

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: const Row(
              children: [
                Icon(Icons.business, color: kPrimaryColor),
                SizedBox(width: 10),
                Text('Thêm Nhà Cung Cấp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),

            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl, 
                      decoration: _inputDecoration('Tên nhà cung cấp *', Icons.storefront)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactCtrl, 
                      decoration: _inputDecoration('Người đại diện liên hệ', Icons.person_outline)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl, 
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Số điện thoại *', Icons.phone)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl, 
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Địa chỉ Email', Icons.email_outlined)
                    ),
                    const SizedBox(height: 12),
                    
                    // --- MENU DROPDOWN 1: LOẠI HÌNH CUNG CẤP ---
                    DropdownButtonFormField<String>(
                      value: supplierType,
                      isExpanded: true,
                      decoration: _inputDecoration('Danh mục cung cấp', Icons.category_outlined),
                      items: const [
                        DropdownMenuItem(value: 'medicine_local', child: Text('Thuốc nội địa')),
                        DropdownMenuItem(value: 'medicine_import', child: Text('Thuốc nhập khẩu')),
                        DropdownMenuItem(value: 'equipment', child: Text('Thiết bị y tế')),
                        DropdownMenuItem(value: 'consumables', child: Text('Vật tư tiêu hao')),
                      ],
                      onChanged: (v) => setStateBuilder(() => supplierType = v!),
                    ),
                    const SizedBox(height: 12),

                    // --- MENU DROPDOWN 2: TRẠNG THÁI HỢP TÁC ---
                    DropdownButtonFormField<String>(
                      value: status,
                      isExpanded: true,
                      decoration: _inputDecoration('Trạng thái đối tác', Icons.gpp_good_outlined),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                        DropdownMenuItem(value: 'reviewing', child: Text('Đang thẩm định')),
                        DropdownMenuItem(value: 'paused', child: Text('Tạm dừng hợp tác')),
                      ],
                      onChanged: (v) => setStateBuilder(() => status = v!),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: addressCtrl, 
                      maxLines: 2,
                      decoration: _inputDecoration('Địa chỉ công ty', Icons.location_on_outlined)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl, 
                      maxLines: 2,
                      decoration: _inputDecoration('Ghi chú thêm', Icons.sticky_note_2_outlined)
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đủ Tên và Số điện thoại!'), backgroundColor: Colors.orange)
                    );
                    return;
                  }

                  // Khởi tạo Model chuẩn gửi lên API (Nhận cả thuộc tính dropdown lựa chọn)
                  final newSupplier = SupplierModel(
                    supplierName: nameCtrl.text.trim(),
                    contactName: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    supplierType: supplierType,
                    status: status,
                    address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  );

                  Navigator.pop(context); 
                  setState(() => _isLoading = true);

                  // --- 2. GỌI API THÊM MỚI NHÀ CUNG CẤP (POST) ---
                  final result = await ApiSupplier.createSupplier(newSupplier);

                  setState(() => _isLoading = false);

                  if (result != null) {
                   Navigator.pop(context); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎉 Thêm '${result.supplierName}' thành công!"), 
        backgroundColor: Colors.green
      )
    );
                    _fetchSuppliers(); // Nạp lại danh sách mới cập nhật từ Server
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thêm nhà cung cấp thất bại! Số điện thoại có thể đã tồn tại.'), backgroundColor: Colors.red)
                    );
                  }
                },
                child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- 3. HÀM GỌI API XÓA NHÀ CUNG CẤP (DELETE) ---
  Future<void> _deleteSupplierItem(String id, String name) async {
    // Hiển thị hộp thoại xác nhận trước khi xóa tránh người dùng ấn nhầm
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhà cung cấp "$name" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      setState(() => _isLoading = true);
      final isSuccess = await ApiSupplier.deleteSupplier(id);
      setState(() => _isLoading = false);

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gỡ nhà cung cấp thành công!'), backgroundColor: Colors.green)
        );
        _fetchSuppliers(); // Đồng bộ tải lại danh sách mới sau khi xóa
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thất bại! Vui lòng thử lại.'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Hàm helper đổi nhãn hiển thị cho đẹp giao diện
  String _mapTypeToLabel(String? type) {
    switch (type) {
      case 'medicine_local': return 'Thuốc nội địa';
      case 'medicine_import': return 'Thuốc nhập khẩu';
      case 'equipment': return 'Thiết bị y tế';
      case 'consumables': return 'Vật tư tiêu hao';
      default: return 'Chưa phân loại';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản Lý Nhà Cung Cấp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSupplierDialog, 
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Nhà Cung Cấp'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final s = suppliers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.local_shipping, color: kPrimaryColor),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(s['supplierName'] ?? 'Không rõ tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _mapTypeToLabel(s['supplierType']), 
                                style: const TextStyle(fontSize: 10, color: kPrimaryColor, fontWeight: FontWeight.bold)
                              ),
                            )
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text('Đại diện: ${s['contactName'] ?? 'N/A'}\nSĐT: ${s['phone']}\nĐC: ${s['address'] ?? 'Chưa cập nhật'}'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            if (s['id'] != null) {
                              _deleteSupplierItem(s['id'].toString(), s['supplierName'].toString());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không tìm thấy ID đối tượng dữ liệu hợp lệ trên server.'))
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Danh sách nhà cung cấp đang trống",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.6), size: 20),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      floatingLabelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
      
      isDense: true, 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}