import 'package:flutter/material.dart';
import '../../services/api_categoryOfMedicine.dart'; 
import '../../models/category_model.dart'; 

class AddCategoryDialog extends StatefulWidget {
  final Color primaryColor;

  const AddCategoryDialog({
    Key? key, 
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Quản lý trạng thái danh sách danh mục
  List<CategoryModel> _existingCategories = [];
  bool _isLoadingList = true; // Loading cho danh sách ban đầu
  bool _isSubmitting = false; // Loading khi bấm nút thêm mới

  @override
  void Initialize() {
    super.initState();
    _loadCategories(); // Tải danh sách khi vừa mở hộp thoại lên
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Hàm tải danh sách danh mục hiện tại từ API
  Future<void> _loadCategories() async {
    setState(() => _isLoadingList = true);
    try {
      final list = await ApiCategoryOfMedicine.getAllCategories();
      setState(() {
        _existingCategories = list;
      });
    } catch (e) {
      print("Lỗi tải danh sách: $e");
    } finally {
      setState(() => _isLoadingList = false);
    }
  }

  // Hàm xử lý khi bấm nút "Xác Nhận Thêm"
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String name = _categoryNameController.text.trim();
    String description = _descriptionController.text.trim();

    CategoryModel? newCategory = await ApiCategoryOfMedicine.createCategory(
      categoryname: name,
      description: description.isNotEmpty ? description : null,
    );

    setState(() => _isSubmitting = false);

    if (newCategory != null) {
      // Clear các ô nhập liệu sau khi thêm thành công để người dùng có thể nhập tiếp nếu muốn
      _categoryNameController.clear();
      _descriptionController.clear();
      
      // Đóng bàn phím ảo
      FocusScope.of(context).unfocus();

      // Cập nhật trực tiếp vào danh sách đang hiển thị bên dưới để xem luôn
      setState(() {
        _existingCategories.insert(0, newCategory); // Đưa danh mục mới nhất lên đầu danh sách
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm danh mục '${newCategory.categoryname}' thành công!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thêm danh mục thất bại. Tên đã tồn tại hoặc lỗi Server!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đoạn MediaQuery tính toán để giới hạn chiều cao tối đa của Dialog tránh tràn màn hình
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Quản Lý Danh Mục",
            style: TextStyle(fontWeight: FontWeight.bold, color: widget.primaryColor, fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context), // Nút đóng dialog nhanh
          )
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9, // Chiều rộng co giãn theo thiết bị
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PHẦN 1: FORM NHẬP LIỆU THÊM MỚI ---
              TextFormField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                  labelText: "Tên danh mục thuốc *",
                  hintText: "Ví dụ: Thuốc bôi, Siro...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.folder_open),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên danh mục thuốc!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Mô tả danh mục (Tùy chọn)",
                  hintText: "Nhập công dụng hoặc ghi chú phân loại...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 15),
              
              // Nút bấm thêm mới
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Xác Nhận Thêm Mới", 
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Divider(thickness: 1),
              const SizedBox(height: 10),

              // --- PHẦN 2: TIÊU ĐỀ LIST DANH SÁCH ĐÃ CÓ ---
              const Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    "Danh sách danh mục đã có sẵn:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // --- PHẦN 3: HIỂN THỊ DANH SÁCH ---
              Expanded(
                child: _isLoadingList
                    ? const Center(child: CircularProgressIndicator())
                    : _existingCategories.isEmpty
                        ? const Center(
                            child: Text("Chưa có danh mục nào trong hệ thống", 
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _existingCategories.length,
                            itemBuilder: (context, index) {
                              final category = _existingCategories[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey.shade200)
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: widget.primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.folder, color: widget.primaryColor, size: 18),
                                  ),
                                  title: Text(
                                    category.categoryname,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: category.description != null && category.description!.isNotEmpty
                                      ? Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                                      : const Text("Không có mô tả", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}