import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/clinic_service_provider.dart';
import '../../services/api_clinic_service.dart';
import '../../models/clinic_service.dart';

const Color kPrimaryBlue = Color(0xFF1E60FF);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGray = Color(0xFF64748B);
const Color kBgColor = Color(0xFFF8FAFC);
const Color kBorderColor = Color(0xFFE2E8F0);

class ServiceManagerScreen extends ConsumerStatefulWidget {
  const ServiceManagerScreen({super.key});

  @override
  ConsumerState<ServiceManagerScreen> createState() => _ServiceManagerScreenState();
}

class _ServiceManagerScreenState extends ConsumerState<ServiceManagerScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  String _searchQuery = '';
  final currencyFormatter = NumberFormat('#,###', 'vi_VN');

  // Clear controllers
  void _clearControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _priceController.clear();
  }

  // Parse price text to double
  double _parsePrice(String text) {
    // Remove formatting like commas, dots, currency symbols, and spaces
    final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  // Add Service
  Future<void> _addService() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final duration = _durationController.text.trim();
    final price = _parsePrice(_priceController.text);

    if (name.isEmpty || description.isEmpty || duration.isEmpty || price <= 0) {
      _showErrorSnackBar('Vui lòng nhập đầy đủ và hợp lệ các trường thông tin bắt buộc (*)');
      return;
    }

    final errorMsg = await ApiClinicService.addService(
      name: name,
      description: description,
      duration: duration,
      price: price,
    );

    if (errorMsg == null) {
      _clearControllers();
      ref.invalidate(clinicServiceProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Thêm dịch vụ mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _showErrorSnackBar(errorMsg);
    }
  }

  // Update Service
  Future<void> _updateService(String id) async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final duration = _durationController.text.trim();
    final price = _parsePrice(_priceController.text);

    if (name.isEmpty || description.isEmpty || duration.isEmpty || price <= 0) {
      _showErrorSnackBar('Vui lòng nhập đầy đủ và hợp lệ các trường thông tin bắt buộc (*)');
      return;
    }

    final errorMsg = await ApiClinicService.updateService(
      id: id,
      name: name,
      description: description,
      duration: duration,
      price: price,
    );

    if (errorMsg == null) {
      _clearControllers();
      ref.invalidate(clinicServiceProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Cập nhật dịch vụ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _showErrorSnackBar(errorMsg);
    }
  }

  // Delete Service
  Future<void> _deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này khỏi hệ thống không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: kTextGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final errorMsg = await ApiClinicService.deleteService(id);
    if (errorMsg == null) {
      ref.invalidate(clinicServiceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Đã xóa dịch vụ thành công!'), backgroundColor: Colors.orange),
        );
      }
    } else {
      _showErrorSnackBar(errorMsg);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show Add/Edit Dialog matching user's design EXACTLY
  void _showFormDialog({ClinicService? service}) {
    final isEditing = service != null;

    if (isEditing) {
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _durationController.text = service.duration;
      _priceController.text = currencyFormatter.format(service.price);
    } else {
      _clearControllers();
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 24,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header with Close Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Cập nhật dịch vụ' : 'Thêm dịch vụ mới',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54, size: 22),
                        onPressed: () {
                          _clearControllers();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tên dịch vụ
                  const Text(
                    'Tên dịch vụ *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 15, color: kTextDark),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên dịch vụ',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả
                  const Text(
                    'Mô tả *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15, color: kTextDark),
                      decoration: const InputDecoration(
                        hintText: 'Nhập mô tả dịch vụ',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thời gian & Giá dịch vụ
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thời gian *',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _durationController,
                                style: const TextStyle(fontSize: 15, color: kTextDark),
                                decoration: const InputDecoration(
                                  hintText: 'VD: 30 phút',
                                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giá dịch vụ *',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _priceController,
                                style: const TextStyle(fontSize: 15, color: kTextDark),
                                decoration: const InputDecoration(
                                  hintText: 'VD: 200,000đ',
                                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final number = _parsePrice(value);
                                    final formatted = currencyFormatter.format(number);
                                    _priceController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Hủy Button
                      OutlinedButton(
                        onPressed: () {
                          _clearControllers();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Thêm / Cập nhật Button
                      ElevatedButton(
                        onPressed: () => isEditing ? _updateService(service.id) : _addService(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? 'Cập nhật dịch vụ' : 'Thêm dịch vụ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(clinicServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý dịch vụ phòng khám',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cấu hình danh mục dịch vụ khám, chữa bệnh và xét nghiệm',
                          style: TextStyle(fontSize: 14, color: kTextGray),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showFormDialog(),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text('Thêm dịch vụ mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics Section (thống kê cho dịch vụ)
              asyncServices.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (services) {
                  final totalCount = services.length;
                  final avgPrice = totalCount > 0 
                      ? services.map((s) => s.price).reduce((a, b) => a + b) / totalCount 
                      : 0.0;
                  final maxPrice = totalCount > 0 
                      ? services.map((s) => s.price).reduce((a, b) => a > b ? a : b) 
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Tổng số dịch vụ',
                          '$totalCount dịch vụ',
                          Icons.medical_services_outlined,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Đơn giá trung bình',
                          '${currencyFormatter.format(avgPrice)} đ',
                          Icons.analytics_outlined,
                          const Color(0xFF10B981),
                        ),
                        _buildStatCard(
                          'Đơn giá cao nhất',
                          '${currencyFormatter.format(maxPrice)} đ',
                          Icons.monetization_on_outlined,
                          Colors.orange,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm dịch vụ theo tên hoặc mô tả...',
                      prefixIcon: Icon(Icons.search, color: kTextGray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),

              // Main List/Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: asyncServices.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
                      error: (err, stack) => Center(
                        child: Text(
                          'Có lỗi khi tải danh sách: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (services) {
                        final filteredList = services.where((s) {
                          return s.name.toLowerCase().contains(_searchQuery) ||
                              s.description.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
                                SizedBox(height: 12),
                                Text(
                                  'Chưa có dịch vụ nào hoặc không tìm thấy dịch vụ phù hợp.',
                                  style: TextStyle(color: kTextGray, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: kBorderColor),
                            child: DataTable(
                              headingRowHeight: 52,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 64,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: const [
                                DataColumn(label: Text('Tên dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                                DataColumn(label: Text('Mô tả chi tiết', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                                DataColumn(label: Text('Thời gian khám', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                                DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                              ],
                              rows: filteredList.map((service) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        service.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 300,
                                        child: Text(
                                          service.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: kTextGray, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          service.duration,
                                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${currencyFormatter.format(service.price)} đ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Sửa',
                                            icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                            onPressed: () => _showFormDialog(service: service),
                                          ),
                                          IconButton(
                                            tooltip: 'Xóa',
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                            onPressed: () => _deleteService(service.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: kTextGray, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
