/// Pharmacy (Dược Sĩ) Dashboard Screen.
///
/// Responsibilities (per Use Case Diagram & Class Diagram [pharmacy]):
/// - View incoming prescriptions from doctors
/// - Dispense medication using FEFO (First-Expiry-First-Out) batch logic
///   [Inventory.getEarliestExpiryBatch] from the Class Diagram
/// - Manage drug inventory and batch stock levels
/// - Trigger low-stock alerts [pharmacy.triggerLowStockAlert]
/// - Track expiry dates and flag near-expiry batches
///
/// Layout: Uses [RoleResponsiveScaffold] for:
/// - Web/Desktop: Persistent left sidebar (Teal gradient accent)
/// - Mobile: AppBar + Drawer + content
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/role_responsive_scaffold.dart';
import '../../services/api_pharmacy.dart';

// ── Color Palette (Teal/Green — medical/pharmacy theme) ─────────────────────
const Color _kPrimary = Color(0xFF00695C); // Deep Teal
const Color _kSecondary = Color(0xFF00897B); // Teal
const Color _kAccent = Color(0xFF4DB6AC); // Light Teal
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFF5F7FA);

/// The main Pharmacy dashboard that adapts to Web (sidebar) and Mobile (drawer).
class PharmacyDashboard extends StatelessWidget {
  const PharmacyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleResponsiveScaffold(
      roleTitle: 'Dược Sĩ',
      roleIcon: Icons.local_pharmacy_rounded,
      accentColor: _kPrimary,
      menuItems: const [
        RoleMenuItem(
          icon: Icons.dashboard_rounded,
          label: 'Tổng quan',
        ),
        RoleMenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'Đơn thuốc',
        ),
        RoleMenuItem(
          icon: Icons.inventory_2_rounded,
          label: 'Kho thuốc',
        ),
        RoleMenuItem(
          icon: Icons.category_rounded,
          label: 'Danh mục',
        ),
        RoleMenuItem(
          icon: Icons.warning_amber_rounded,
          label: 'Cảnh báo',
        ),
      ],
      pages: const [
        _PharmacyOverviewPage(),
        _PharmacyPrescriptionPage(),
        _PharmacyInventoryPage(),
        _PharmacyCategoryPage(),
        _PharmacyAlertsPage(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 1: OVERVIEW (Tổng quan)
// ══════════════════════════════════════════════════════════════════════════════

class _PharmacyOverviewPage extends StatelessWidget {
  const _PharmacyOverviewPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng Quan Nhà Thuốc',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── KPI Cards ─────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildKpiCard(
                    label: 'Đơn chờ cấp',
                    value: '12',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange,
                  ),
                  _buildKpiCard(
                    label: 'Đã cấp hôm nay',
                    value: '38',
                    icon: Icons.medication_rounded,
                    color: _kPrimary,
                  ),
                  _buildKpiCard(
                    label: 'Sắp hết hàng',
                    value: '5',
                    icon: Icons.inventory_outlined,
                    color: Colors.red,
                  ),
                  _buildKpiCard(
                    label: 'Sắp hết hạn',
                    value: '3',
                    icon: Icons.timer_off_rounded,
                    color: Colors.deepOrange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Pending Prescriptions ─────────────────────────────────────────
          _buildSectionCard(
            title: 'Đơn thuốc chờ cấp',
            icon: Icons.receipt_long_rounded,
            child: _PendingPrescriptionList(),
          ),
          const SizedBox(height: 20),

          // ── Low Stock Alerts ──────────────────────────────────────────────
          _buildSectionCard(
            title: 'Thuốc sắp hết hàng',
            icon: Icons.warning_amber_rounded,
            child: _LowStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Pending Prescription List ─────────────────────────────────────────────────
class _PendingPrescriptionList extends StatelessWidget {
  _PendingPrescriptionList();

  final List<Map<String, dynamic>> _mockPrescriptions = [
    {
      'patient': 'Nguyễn Văn A',
      'doctor': 'BS. Trần Minh',
      'items': 3,
      'time': '08:20',
      'rx': 'RX-001',
    },
    {
      'patient': 'Lê Thị B',
      'doctor': 'BS. Nguyễn Hà',
      'items': 2,
      'time': '09:00',
      'rx': 'RX-002',
    },
    {
      'patient': 'Phạm Văn C',
      'doctor': 'BS. Lê Hương',
      'items': 5,
      'time': '09:45',
      'rx': 'RX-003',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _mockPrescriptions.map((rx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kPrimary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rx['patient'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${rx['rx']} • ${rx['doctor']} • ${rx['items']} loại thuốc',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                rx['time'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cấp thuốc: ${rx['patient']} (FEFO)'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(72, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cấp', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Low Stock List ────────────────────────────────────────────────────────────
class _LowStockList extends StatelessWidget {
  const _LowStockList();

  @override
  Widget build(BuildContext context) {
    final drugs = [
      {'name': 'Paracetamol 500mg', 'stock': 15, 'min': 50, 'unit': 'viên'},
      {'name': 'Amoxicillin 250mg', 'stock': 8, 'min': 30, 'unit': 'viên'},
      {'name': 'Metformin 500mg', 'stock': 20, 'min': 100, 'unit': 'viên'},
    ];

    return Column(
      children: drugs.map((d) {
        final stock = d['stock'] as int;
        final min = d['min'] as int;
        final ratio = stock / min;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  d['name'] as String,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.red,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stock / $min ${d['unit']}',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hết hàng',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 2: PRESCRIPTIONS (Đơn thuốc)
// ══════════════════════════════════════════════════════════════════════════════

class _PharmacyPrescriptionPage extends StatelessWidget {
  const _PharmacyPrescriptionPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản Lý Đơn Thuốc',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách đơn thuốc từ bác sĩ. Áp dụng FEFO khi cấp thuốc.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // FEFO notice banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hệ thống tự động áp dụng FEFO (First-Expiry-First-Out) '
                    'để đảm bảo an toàn cho bệnh nhân.',
                    style: TextStyle(
                        color: _kPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Full prescription list (reuse pending list)
          _PendingPrescriptionList(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 3: INVENTORY (Kho thuốc)
// ══════════════════════════════════════════════════════════════════════════════

class _PharmacyInventoryPage extends StatefulWidget {
  const _PharmacyInventoryPage();

  @override
  State<_PharmacyInventoryPage> createState() => _PharmacyInventoryPageState();
}

class _PharmacyInventoryPageState extends State<_PharmacyInventoryPage> {
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final cats = await PharmacyService.getCategories();
      final meds = await PharmacyService.getMedicines();
      setState(() {
        _categories = cats;
        _medicines = meds;
        _filteredMedicines = meds;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar("Lỗi tải dữ liệu kho: $e", Colors.red);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = _medicines;
      } else {
        _filteredMedicines = _medicines.where((med) {
          final name = (med['name'] ?? '').toString().toLowerCase();
          final code = (med['medicineCode'] ?? '').toString().toLowerCase();
          final active =
              (med['activeIngredient'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              code.contains(query) ||
              active.contains(query);
        }).toList();
      }
    });
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMedicineDialog([Map<String, dynamic>? medicine]) {
    final isEdit = medicine != null;

    final codeController =
        TextEditingController(text: medicine?['medicineCode'] ?? '');
    final nameController = TextEditingController(text: medicine?['name'] ?? '');
    final ingredientController =
        TextEditingController(text: medicine?['activeIngredient'] ?? '');
    final routeController = TextEditingController(
        text: medicine?['routeOfAdministration'] ?? 'Uống');
    final unitController =
        TextEditingController(text: medicine?['unit'] ?? 'Viên');
    final stockController = TextEditingController(
        text: medicine?['stockLevel']?.toString() ?? '100');
    final reorderController = TextEditingController(
        text: medicine?['reorderLevel']?.toString() ?? '10');
    final priceController =
        TextEditingController(text: medicine?['unitPrice']?.toString() ?? '0');
    final manufacturerController =
        TextEditingController(text: medicine?['manufacturer'] ?? '');

    // Parse category ID
    String? selectedCategoryId;
    if (isEdit && medicine['categoryId'] != null) {
      if (medicine['categoryId'] is Map) {
        selectedCategoryId = medicine['categoryId']['_id'];
      } else {
        selectedCategoryId = medicine['categoryId'].toString();
      }
    } else if (_categories.isNotEmpty) {
      selectedCategoryId = _categories.first['_id'];
    }

    // Expiry date picker support
    DateTime selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
    if (isEdit && medicine['expiryDate'] != null) {
      selectedExpiryDate = DateTime.parse(medicine['expiryDate']);
    }
    final expiryController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(selectedExpiryDate),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Sửa Thông Tin Thuốc' : 'Thêm Thuốc Mới',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _kPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: !isEdit,
                      decoration: const InputDecoration(
                        labelText: 'Mã thuốc *',
                        hintText: 'VD: MED-001',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên thuốc *',
                        hintText: 'VD: Glucophage',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ingredientController,
                      decoration: const InputDecoration(
                        labelText: 'Hoạt chất *',
                        hintText: 'VD: Metformin 500mg',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục phân loại *',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['_id'] as String,
                          child: Text(cat['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategoryId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: routeController,
                      decoration: const InputDecoration(
                        labelText: 'Đường dùng *',
                        hintText: 'VD: Uống, Tiêm, Bôi',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn vị tính *',
                        hintText: 'VD: Viên, Vỉ, Chai',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng tồn *',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reorderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ngưỡng cảnh báo hết *',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá (VNĐ) *',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    TextField(
                      controller: expiryController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Ngày hết hạn *',
                        suffixIcon:
                            Icon(Icons.calendar_today, color: _kPrimary),
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiryDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedExpiryDate = picked;
                            expiryController.text =
                                DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: manufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Nhà sản xuất *',
                        hintText: 'VD: Sanofi',
                        labelStyle: TextStyle(color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:
                      const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    final name = nameController.text.trim();
                    final ingredient = ingredientController.text.trim();
                    final route = routeController.text.trim();
                    final unit = unitController.text.trim();
                    final stock =
                        int.tryParse(stockController.text.trim()) ?? 0;
                    final reorder =
                        int.tryParse(reorderController.text.trim()) ?? 10;
                    final price =
                        double.tryParse(priceController.text.trim()) ?? 0.0;
                    final manufacturer = manufacturerController.text.trim();

                    if (code.isEmpty ||
                        name.isEmpty ||
                        ingredient.isEmpty ||
                        selectedCategoryId == null ||
                        route.isEmpty ||
                        unit.isEmpty ||
                        manufacturer.isEmpty) {
                      _showSnackbar('Vui lòng nhập đầy đủ các trường bắt buộc',
                          Colors.orange);
                      return;
                    }

                    final payload = {
                      'medicineCode': code,
                      'name': name,
                      'activeIngredient': ingredient,
                      'categoryId': selectedCategoryId,
                      'routeOfAdministration': route,
                      'unit': unit,
                      'stockLevel': stock,
                      'reorderLevel': reorder,
                      'unitPrice': price,
                      'expiryDate': selectedExpiryDate.toIso8601String(),
                      'manufacturer': manufacturer,
                    };

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    String? err;
                    if (isEdit) {
                      err = await PharmacyService.updateMedicine(
                          medicine['_id'], payload);
                    } else {
                      err = await PharmacyService.createMedicine(payload);
                    }

                    if (err == null) {
                      _showSnackbar(
                          isEdit
                              ? 'Cập nhật thành công!'
                              : 'Thêm thuốc thành công!',
                          _kPrimary);
                      _fetchData();
                    } else {
                      setState(() => _isLoading = false);
                      _showSnackbar('Thất bại: $err', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMedicine(Map<String, dynamic> medicine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
            'Bạn có chắc chắn muốn xóa thuốc "${medicine['name']}" khỏi kho không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final err = await PharmacyService.deleteMedicine(medicine['_id']);
              if (err == null) {
                _showSnackbar('Xóa thuốc thành công!', _kPrimary);
                _fetchData();
              } else {
                setState(() => _isLoading = false);
                _showSnackbar('Thất bại: $err', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kho Thuốc',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý tồn kho và thông tin thuốc chi tiết',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm thuốc mới'),
                onPressed: () {
                  if (_categories.isEmpty) {
                    _showSnackbar(
                        'Vui lòng thêm danh mục trước khi thêm thuốc!',
                        Colors.orange);
                  } else {
                    _openMedicineDialog();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thuốc theo tên, hoạt chất hoặc mã...',
              prefixIcon: const Icon(Icons.search, color: _kPrimary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            )
          else if (_filteredMedicines.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.medication_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Chưa có thuốc nào trong kho.'
                          : 'Không tìm thấy thuốc khớp với từ khóa.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredMedicines.length,
              itemBuilder: (context, index) {
                final med = _filteredMedicines[index];

                // Expiry Date check
                DateTime? expDate;
                if (med['expiryDate'] != null) {
                  expDate = DateTime.tryParse(med['expiryDate']);
                }
                final String formattedExpiry = expDate != null
                    ? DateFormat('dd/MM/yyyy').format(expDate)
                    : 'Không xác định';

                final isLowStock =
                    (med['stockLevel'] ?? 0) <= (med['reorderLevel'] ?? 10);
                final isExpired =
                    expDate != null && expDate.isBefore(DateTime.now());
                final isNearExpiry = expDate != null &&
                    !isExpired &&
                    expDate
                        .isBefore(DateTime.now().add(const Duration(days: 60)));

                // Resolve Category Name
                String catName = 'N/A';
                if (med['categoryId'] != null) {
                  if (med['categoryId'] is Map) {
                    catName = med['categoryId']['name'] ?? 'N/A';
                  } else {
                    // Search in loaded categories
                    final catObj = _categories.firstWhere(
                      (c) => c['_id'] == med['categoryId'].toString(),
                      orElse: () => {},
                    );
                    catName = catObj['name'] ?? 'N/A';
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: isLowStock || isExpired
                        ? Border.all(color: Colors.red.shade200)
                        : isNearExpiry
                            ? Border.all(color: Colors.orange.shade200)
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isExpired || isLowStock
                              ? Colors.red.withOpacity(0.1)
                              : isNearExpiry
                                  ? Colors.orange.withOpacity(0.1)
                                  : _kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.medication_liquid_rounded,
                          color: isExpired || isLowStock
                              ? Colors.red
                              : isNearExpiry
                                  ? Colors.orange
                                  : _kPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    med['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    med['medicineCode'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                if (isLowStock) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Sắp hết hàng',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isExpired) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'HẾT HẠN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (isNearExpiry) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Cận hạn',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hoạt chất: ${med['activeIngredient'] ?? 'N/A'} • Đường dùng: ${med['routeOfAdministration'] ?? 'N/A'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phân loại: $catName • Nhà SX: ${med['manufacturer'] ?? 'N/A'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tồn kho: ${med['stockLevel'] ?? 0} ${med['unit'] ?? ''} • Giá: ${NumberFormat('#,###', 'vi_VN').format(med['unitPrice'] ?? 0)} đ • Hạn dùng: $formattedExpiry',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isExpired
                                    ? Colors.red
                                    : isNearExpiry
                                        ? Colors.orange.shade800
                                        : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openMedicineDialog(med),
                            icon: const Icon(Icons.edit_outlined,
                                color: _kPrimary, size: 20),
                            tooltip: 'Chỉnh sửa',
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteMedicine(med),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 20),
                            tooltip: 'Xóa',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 4: ALERTS (Cảnh báo)
// ══════════════════════════════════════════════════════════════════════════════

class _PharmacyAlertsPage extends StatelessWidget {
  const _PharmacyAlertsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cảnh Báo Kho Thuốc',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Các cảnh báo tự động từ hệ thống giám sát kho.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Alert cards
          _buildAlertCard(
            icon: Icons.inventory_outlined,
            title: 'Sắp hết hàng (5 loại)',
            subtitle:
                'Paracetamol, Amoxicillin, Metformin... cần nhập thêm trong 7 ngày.',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.timer_off_rounded,
            title: 'Sắp hết hạn (3 lô)',
            subtitle:
                'Lô Amoxicillin B-2023-05 hết hạn trong 25 ngày. Ưu tiên cấp phát.',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.check_circle_outline,
            title: 'Kho hoạt động bình thường',
            subtitle: 'Không có lô hàng nào đã hết hạn. Hệ thống ổn định.',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 5: CATEGORIES (Danh mục thuốc)
// ══════════════════════════════════════════════════════════════════════════════

class _PharmacyCategoryPage extends StatefulWidget {
  const _PharmacyCategoryPage();

  @override
  State<_PharmacyCategoryPage> createState() => _PharmacyCategoryPageState();
}

class _PharmacyCategoryPageState extends State<_PharmacyCategoryPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await PharmacyService.getCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar("Lỗi tải danh mục: $e", Colors.red);
    }
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCategoryDialog([Map<String, dynamic>? category]) {
    final isEdit = category != null;
    final codeController =
        TextEditingController(text: category?['categoryCode'] ?? '');
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descController =
        TextEditingController(text: category?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Sửa Danh Mục' : 'Thêm Danh Mục Mới',
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã danh mục',
                  hintText: 'VD: CAT-01',
                  labelStyle: TextStyle(color: _kPrimary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'VD: Kháng sinh',
                  labelStyle: TextStyle(color: _kPrimary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả danh mục (tùy chọn)',
                  labelStyle: TextStyle(color: _kPrimary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              final desc = descController.text.trim();

              if (code.isEmpty || name.isEmpty) {
                _showSnackbar(
                    'Vui lòng nhập đầy đủ mã và tên danh mục', Colors.orange);
                return;
              }

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              String? err;
              if (isEdit) {
                err = await PharmacyService.updateCategory(
                    category['_id'], code, name, desc);
              } else {
                err = await PharmacyService.createCategory(code, name, desc);
              }

              if (err == null) {
                _showSnackbar(
                    isEdit
                        ? 'Cập nhật thành công!'
                        : 'Tạo danh mục thành công!',
                    _kPrimary);
                _fetchCategories();
              } else {
                setState(() => _isLoading = false);
                _showSnackbar('Thất bại: $err', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${category['name']}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final err = await PharmacyService.deleteCategory(category['_id']);
              if (err == null) {
                _showSnackbar('Xóa danh mục thành công!', _kPrimary);
                _fetchCategories();
              } else {
                setState(() => _isLoading = false);
                _showSnackbar('Thất bại: $err', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh Mục Thuốc',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary),
                  ),
                  SizedBox(height: 4),
                  Text('Quản lý phân loại danh mục thuốc trong hệ thống',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm danh mục'),
                onPressed: () => _openCategoryDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            )
          else if (_categories.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.category_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Chưa có danh mục thuốc nào.',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category_rounded,
                            color: _kPrimary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mã: ${cat['categoryCode']} • ${cat['description'] ?? 'Không có mô tả'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openCategoryDialog(cat),
                        icon: const Icon(Icons.edit_outlined,
                            color: _kPrimary, size: 20),
                        tooltip: 'Sửa',
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(cat),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red, size: 20),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
