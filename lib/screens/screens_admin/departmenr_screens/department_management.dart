import 'package:flutter/material.dart';
import '../../../services/api_department.dart';

class DepartmentManagement extends StatefulWidget {
  @override
  _DepartmentManagementState createState() => _DepartmentManagementState();
}

class _DepartmentManagementState extends State<DepartmentManagement> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> departments = [];

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> fetchDepartments() async {
    try {
      final data = await DepartmentService.getDepartments();
      setState(() {
        departments = data;
      });
    } catch (e) {
      showSnackbar('Lỗi khi tải dữ liệu: $e', isError: true);
    }
  }

  void _addDepartment() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm phòng ban mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên phòng ban'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả phòng ban'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final description = _descriptionController.text.trim();

                if (name.isEmpty || description.isEmpty) {
                  showSnackbar('Vui lòng điền đầy đủ thông tin', isError: true);
                  return;
                }

                final result =
                    await DepartmentService.addDepartment(name, description);
                if (!context.mounted) return;
                if (result == "success") {
                  Navigator.pop(context);
                  showSnackbar("Thêm thành công");
                  fetchDepartments();
                } else {
                  showSnackbar(result ?? 'Lỗi không xác định', isError: true);
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _editDepartment(dynamic department) {
    _nameController.text = department['departmentName'] ?? '';
    _descriptionController.text = department['description'] ?? '';
    

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa phòng ban'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên phòng ban'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả phòng ban'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                final newDescription = _descriptionController.text.trim();

                if (newName.isEmpty || newDescription.isEmpty) {
                  showSnackbar('Vui lòng điền đầy đủ thông tin', isError: true);
                  return;
                }

                final result = await DepartmentService.updateDepartment(
                    department['id'], newName, newDescription);
                if (!context.mounted) return;
                if (result == "success") {
                  Navigator.pop(context);
                  showSnackbar("Cập nhật thành công");
                  fetchDepartments();
                } else {
                  showSnackbar(result ?? 'Lỗi không xác định', isError: true);
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDepartment(String id) async {
    final result = await DepartmentService.deleteDepartment(id);
    if (result == "success") {
      showSnackbar("Xóa thành công");
      fetchDepartments();
    } else {
      showSnackbar(result ?? "Lỗi khi xóa", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý phòng ban'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addDepartment,
          ),
        ],
      ),
      body: departments.isEmpty
          ? Center(child: Text('Không có dữ liệu'))
          : ListView.builder(
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final dept = departments[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(dept['departmentName'] ?? ''),
                    subtitle: Text(dept['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editDepartment(dept),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDepartment(dept['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
