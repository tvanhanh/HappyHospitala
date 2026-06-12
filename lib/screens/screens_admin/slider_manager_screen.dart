/// Admin Slider Management Screen — Full CRUD.
///
/// [Core-2] Allows Admin to:
/// - View all slider items (active + inactive)
/// - Add new slider with imageUrl, title, subtitle
/// - Toggle active/inactive status
/// - Delete sliders
///
/// Uses [SliderService] from [home_provider.dart].
/// Changes are reflected on the Patient Home Screen dynamically.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/home_provider.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);

// Provider for admin slider list (includes inactive)
final adminSliderProvider = FutureProvider<List<SliderItem>>((ref) async {
  return SliderService.getAllSliders();
});

class AdminSliderManagerScreen extends ConsumerStatefulWidget {
  const AdminSliderManagerScreen({super.key});

  @override
  ConsumerState<AdminSliderManagerScreen> createState() =>
      _AdminSliderManagerScreenState();
}

class _AdminSliderManagerScreenState extends ConsumerState<AdminSliderManagerScreen> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _showAddForm = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSliders = ref.watch(adminSliderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Quản Lý Slider',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(adminSliderProvider),
          ),
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add_circle_outline, color: Colors.white),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
            tooltip: _showAddForm ? 'Đóng form' : 'Thêm slider mới',
          ),
        ],
      ),
      floatingActionButton: _showAddForm ? null : FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: () => setState(() => _showAddForm = true),
        icon: const Icon(Icons.add_photo_alternate_outlined,
            color: Colors.white),
        label: const Text('Thêm Slider',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: asyncSliders.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Không thể tải dữ liệu slider'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminSliderProvider),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (sliders) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
              if (_showAddForm) _buildAddSliderForm(),
              if (sliders.isEmpty)
                Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Chưa có slider nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (!_showAddForm)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm slider đầu tiên'),
                          onPressed: () => setState(() => _showAddForm = true),
                          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                        ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: sliders.length,
                    itemBuilder: (ctx, i) => _SliderCard(
                      item: sliders[i],
                      onToggle: (active) async {
                        await SliderService.toggleSlider(sliders[i].id, active);
                        ref.invalidate(adminSliderProvider);
                      },
                      onDelete: () async {
                        final confirm = await _confirmDelete(context);
                        if (confirm == true) {
                          await SliderService.deleteSlider(sliders[i].id);
                          ref.invalidate(adminSliderProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa slider'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
            ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: const Text(
            'Bạn có chắc muốn xóa slider này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSliderForm() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thêm Slider Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isUploading ? null : () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setState(() {
                      _selectedImage = picked;
                      _imageBytes = bytes;
                    });
                  }
                },
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.5), style: BorderStyle.solid),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _imageBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: _kPrimary),
                              SizedBox(height: 8),
                              Text('Nhấn để chọn ảnh banner', style: TextStyle(color: _kPrimary)),
                            ],
                          )
                        : Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              if (_selectedImage == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Vui lòng chọn hình ảnh', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  prefixIcon: const Icon(Icons.title_rounded, color: _kPrimary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleCtrl,
                decoration: InputDecoration(
                  labelText: 'Mô tả phụ',
                  prefixIcon: const Icon(Icons.subtitles_outlined, color: _kPrimary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isUploading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate() || _selectedImage == null) return;
                          setState(() => _isUploading = true);

                          final ok = await SliderService.createSlider(
                            _selectedImage!,
                            _titleCtrl.text.trim(),
                            _subtitleCtrl.text.trim(),
                          );

                          setState(() => _isUploading = false);

                          if (mounted) {
                            if (ok) {
                              _titleCtrl.clear();
                              _subtitleCtrl.clear();
                              setState(() {
                                _selectedImage = null;
                                _imageBytes = null;
                                _showAddForm = false; // Hide form on success
                              });
                              ref.invalidate(adminSliderProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã thêm slider!'), backgroundColor: Colors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thêm thất bại'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Thêm Slider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final SliderItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _SliderCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive
              ? _kPrimary.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBg(),
                    )
                  : _placeholderBg(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.title.isNotEmpty)
                            Text(
                              item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    // Active toggle
                    Switch.adaptive(
                      value: item.isActive,
                      activeColor: _kPrimary,
                      onChanged: onToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isActive
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.isActive ? '✅ Đang hiển thị' : '⏸ Đã ẩn',
                        style: TextStyle(
                          color: item.isActive
                              ? Colors.green.shade700
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 22),
                      onPressed: onDelete,
                      tooltip: 'Xóa slider',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00B0FF)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white54, size: 48),
      ),
    );
  }
}
