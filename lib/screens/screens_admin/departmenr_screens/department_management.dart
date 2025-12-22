import 'package:flutter/material.dart';
import '../../../services/api_department.dart';

// --- PALETTE MÀU (Đồng bộ) ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kIconColor = Color(0xFF5C6BC0); // Màu Indigo nhạt cho icon

class DepartmentManagement extends StatefulWidget {
  @override
  _DepartmentManagementState createState() => _DepartmentManagementState();
}

class _DepartmentManagementState extends State<DepartmentManagement> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> departments = [];
  bool isLoading = false; // Thêm trạng thái loading

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> fetchDepartments() async {
    setState(() => isLoading = true);
    try {
      final data = await DepartmentService.getDepartments();
      setState(() {
        departments = data;
      });
    } catch (e) {
      showSnackbar('Lỗi kết nối: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- DIALOG THÊM/SỬA (ĐÃ TỐI ƯU UI) ---
  void _showFormDialog({dynamic department}) {
    final isEdit = department != null;
    if (isEdit) {
      _nameController.text = department['departmentName'] ?? '';
      _descriptionController.text = department['description'] ?? '';
    } else {
      _nameController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_note : Icons.add_business,
                  color: kPrimaryColor),
              SizedBox(width: 10),
              Text(isEdit ? 'Cập nhật' : 'Thêm mới',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, 'Tên phòng ban', Icons.business),
              SizedBox(height: 15),
              _buildTextField(
                  _descriptionController, 'Mô tả chi tiết', Icons.description),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final desc = _descriptionController.text.trim();

                if (name.isEmpty || desc.isEmpty) {
                  showSnackbar('Vui lòng nhập đầy đủ thông tin', isError: true);
                  return;
                }

                Navigator.pop(context); // Đóng dialog trước khi gọi API

                String? result;
                if (isEdit) {
                  result = await DepartmentService.updateDepartment(
                      department['id'], name, desc);
                } else {
                  result = await DepartmentService.addDepartment(name, desc);
                }

                if (result == "success") {
                  showSnackbar(isEdit
                      ? "Đã cập nhật phòng ban"
                      : "Đã thêm phòng ban mới");
                  fetchDepartments();
                } else {
                  showSnackbar(result ?? 'Có lỗi xảy ra', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEdit ? 'Lưu thay đổi' : 'Tạo mới',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }

  void _deleteDepartment(String id) async {
    // Thêm Dialog xác nhận xóa cho an toàn
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text(
            "Bạn có chắc chắn muốn xóa phòng ban này? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await DepartmentService.deleteDepartment(id);
              if (result == "success") {
                showSnackbar("Đã xóa thành công");
                fetchDepartments();
              } else {
                showSnackbar(result ?? "Lỗi khi xóa", isError: true);
              }
            },
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản Lý Phòng Ban',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${departments.length} đơn vị trực thuộc',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchDepartments),
        ],
      ),

      body: Column(
        children: [
          // 1. THANH TÌM KIẾM (Giao diện)
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30)),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              height: 45,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text("Tìm kiếm phòng ban...",
                          style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ),

          // 2. DANH SÁCH PHÒNG BAN
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : departments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: departments.length,
                        itemBuilder: (context, index) {
                          return _buildDepartmentCard(departments[index]);
                        },
                      ),
          ),
        ],
      ),
// 3. NÚT THÊM (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_business),
        label: Text("Thêm Phòng Ban",
            style: TextStyle(
                fontWeight: FontWeight.bold)), // Có thể thêm style bold cho đẹp
      ),
    );
  }

  // --- WIDGET CON: CARD PHÒNG BAN ---
  Widget _buildDepartmentCard(dynamic dept) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.blueGrey.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kIconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.apartment_rounded, color: kIconColor, size: 28),
        ),
        title: Text(
          dept['departmentName'] ?? 'Không tên',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey.shade800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            dept['description'] ?? 'Chưa có mô tả',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') _showFormDialog(department: dept);
            if (value == 'delete') _deleteDepartment(dept['id']);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Text("Chỉnh sửa")
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Text("Xóa")
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.domain_disabled, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 15),
          Text("Chưa có phòng ban nào",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
