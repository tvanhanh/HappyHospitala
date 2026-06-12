/// Pharmacy (Dược Sĩ) Dashboard Screen.
///
/// Responsibilities (per Use Case Diagram & Class Diagram [PharmacyManager]):
/// - View incoming prescriptions from doctors
/// - Dispense medication using FEFO (First-Expiry-First-Out) batch logic
///   [Inventory.getEarliestExpiryBatch] from the Class Diagram
/// - Manage drug inventory and batch stock levels
/// - Trigger low-stock alerts [PharmacyManager.triggerLowStockAlert]
/// - Track expiry dates and flag near-expiry batches
///
/// Layout: Uses [RoleResponsiveScaffold] for:
/// - Web/Desktop: Persistent left sidebar (Teal gradient accent)
/// - Mobile: AppBar + Drawer + content
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/role_responsive_scaffold.dart';

// ── Color Palette (Teal/Green — medical/pharmacy theme) ─────────────────────
const Color _kPrimary = Color(0xFF00695C);   // Deep Teal
const Color _kSecondary = Color(0xFF00897B); // Teal
const Color _kAccent = Color(0xFF4DB6AC);    // Light Teal
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
          icon: Icons.warning_amber_rounded,
          label: 'Cảnh báo',
        ),
      ],
      pages: const [
        _PharmacyOverviewPage(),
        _PharmacyPrescriptionPage(),
        _PharmacyInventoryPage(),
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
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                rx['time'] as String,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Cấp thuốc: ${rx['patient']} (FEFO)'),
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
                      style: const TextStyle(
                          fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
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

class _PharmacyInventoryPage extends StatelessWidget {
  const _PharmacyInventoryPage();

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
              const Text(
                'Kho Thuốc',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nhập kho'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thuốc...',
              prefixIcon: const Icon(Icons.search, color: _kPrimary),
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

          // Drug cards
          ...List.generate(6, (i) => _DrugInventoryCard(index: i)),
        ],
      ),
    );
  }
}

class _DrugInventoryCard extends StatelessWidget {
  final int index;
  const _DrugInventoryCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final drugs = [
      {
        'name': 'Paracetamol 500mg',
        'stock': 245,
        'unit': 'viên',
        'expiry': '12/2025',
        'low': false
      },
      {
        'name': 'Amoxicillin 250mg',
        'stock': 8,
        'unit': 'viên',
        'expiry': '06/2025',
        'low': true
      },
      {
        'name': 'Metformin 500mg',
        'stock': 180,
        'unit': 'viên',
        'expiry': '03/2026',
        'low': false
      },
      {
        'name': 'Lisinopril 10mg',
        'stock': 95,
        'unit': 'viên',
        'expiry': '09/2025',
        'low': false
      },
      {
        'name': 'Atorvastatin 20mg',
        'stock': 12,
        'unit': 'viên',
        'expiry': '01/2026',
        'low': true
      },
      {
        'name': 'Omeprazole 20mg',
        'stock': 320,
        'unit': 'viên',
        'expiry': '08/2026',
        'low': false
      },
    ];

    if (index >= drugs.length) return const SizedBox.shrink();
    final d = drugs[index];
    final isLow = d['low'] as bool;
    final stock = d['stock'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: isLow ? Border.all(color: Colors.red.shade200) : null,
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
          // Drug icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLow
                  ? Colors.red.withOpacity(0.1)
                  : _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.medication_liquid_rounded,
              color: isLow ? Colors.red : _kPrimary,
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
                    Text(
                      d['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isLow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tồn kho: $stock ${d['unit']}  •  Hạn: ${d['expiry']}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: _kPrimary, size: 20),
            tooltip: 'Chỉnh sửa',
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
