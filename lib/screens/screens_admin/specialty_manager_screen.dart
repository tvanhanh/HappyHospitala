import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/specialty_provider.dart';
import '../../services/specialty_service.dart';

const Color _kPrimary = Color(0xFF1565C0);

class SpecialtyManagerScreen extends ConsumerStatefulWidget {
  const SpecialtyManagerScreen({super.key});

  @override
  ConsumerState<SpecialtyManagerScreen> createState() =>
      _SpecialtyManagerScreenState();
}

class _SpecialtyManagerScreenState
    extends ConsumerState<SpecialtyManagerScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _searchQuery = '';

  Future<void> _addSpecialty() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackBar('Tên chuyên khoa không được để trống');
      return;
    }

    final errorMessage = await SpecialtyService.addSpecialty(
      name: name,
      description: description,
      imageUrl: imageUrl,
    );

    if (errorMessage == null) {
      _clearControllers();
      ref.invalidate(specialtyProvider);
      if (mounted) Navigator.pop(context);
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _updateSpecialty(String id) async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackBar('Tên chuyên khoa không được để trống');
      return;
    }

    final errorMessage = await SpecialtyService.updateSpecialty(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
    );

    if (errorMessage == null) {
      _clearControllers();
      ref.invalidate(specialtyProvider);
      if (mounted) Navigator.pop(context);
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _deleteSpecialty(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa chuyên khoa này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final errorMessage = await SpecialtyService.deleteSpecialty(id);

    if (errorMessage == null) {
      ref.invalidate(specialtyProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã xóa chuyên khoa!')));
      }
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // DIALOG ĐƯỢC LÀM ĐẸP
  void _showFormDialog(
      {String? id,
      String? initialName,
      String? initialDesc,
      String? initialImg}) {
    final isEditing = id != null;

    if (isEditing) {
      _nameController.text = initialName ?? '';
      _descriptionController.text = initialDesc ?? '';
      _imageUrlController.text = initialImg ?? '';
    } else {
      _clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note : Icons.add_circle_outline,
                color: _kPrimary, size: 28),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Sửa Chuyên Khoa' : 'Thêm Chuyên Khoa',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500, // Cố định độ rộng của form để không bị quá hẹp trên Web
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên chuyên khoa (VD: Tim mạch)',
                    prefixIcon: const Icon(Icons.local_hospital_outlined,
                        color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả chuyên khoa',
                    prefixIcon: const Icon(Icons.description_outlined,
                        color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Link ảnh URL (Flaticon)',
                    prefixIcon:
                        const Icon(Icons.image_outlined, color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () {
              _clearControllers();
              Navigator.pop(context);
            },
            child: const Text('Hủy',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => isEditing ? _updateSpecialty(id) : _addSpecialty(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isEditing ? 'Lưu Thay Đổi' : 'Thêm Mới',
                style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSpecialties = ref.watch(specialtyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        // ConstrainedBox là "chìa khóa" giúp nội dung không bị bè ra hai bên
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // THANH TÌM KIẾM
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Container(
                  // Đưa boxShadow và màu nền ra Container bên ngoài
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm chuyên khoa...',
                      prefixIcon: const Icon(Icons.search, color: _kPrimary),
                      // Bỏ filled và fillColor ở đây vì Container đã lo phần nền
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              // DANH SÁCH CHUYÊN KHOA
              Expanded(
                child: asyncSpecialties.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Lỗi: $err')),
                  data: (specialties) {
                    final filteredSpecialties = specialties.where((spec) {
                      return spec.name.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredSpecialties.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Không tìm thấy chuyên khoa nào.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredSpecialties.length,
                      itemBuilder: (context, index) {
                        final spec = filteredSpecialties[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: spec.imageUrl.isNotEmpty &&
                                        spec.imageUrl.startsWith('http')
                                    ? Image.network(
                                        spec.imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.local_hospital,
                                                color: _kPrimary, size: 30),
                                      )
                                    : const Icon(Icons.local_hospital,
                                        color: _kPrimary, size: 30),
                              ),
                              title: Text(
                                spec.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _kPrimary,
                                    fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  spec.description.isNotEmpty
                                      ? spec.description
                                      : 'Không có mô tả',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Sửa',
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.orange),
                                    onPressed: () => _showFormDialog(
                                      id: spec.id,
                                      initialName: spec.name,
                                      initialDesc: spec.description,
                                      initialImg: spec.imageUrl,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _deleteSpecialty(spec.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
