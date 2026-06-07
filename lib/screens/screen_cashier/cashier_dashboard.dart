/// Cashier (Thu Ngân) Dashboard Screen.
///
/// Responsibilities (per Use Case Diagram):
/// - Process patient payment for medical services (UC: Process Payment)
/// - Generate and print invoices (UC: Generate Invoice)
/// - View daily revenue summary and statistics
/// - Handle online payment gateway integration (VNPay, Momo)
/// - Confirm payment → anchors [Invoice.transactionHash] on Ethereum chain
///
/// Layout: Uses [RoleResponsiveScaffold] for:
/// - Web/Desktop: Persistent left sidebar (Primary Blue gradient)
/// - Mobile: AppBar + Drawer + content
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/role_responsive_scaffold.dart';
import '../../models/invoice.dart';

// ── Color Palette (Primary Blue — consistent with system theme) ──────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kSecondary = Color(0xFF1976D2);
const Color _kAccent = Color(0xFF42A5F5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFF5F7FA);

/// The main Cashier dashboard that adapts to Web (sidebar) and Mobile (drawer).
class CashierDashboard extends StatelessWidget {
  const CashierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleResponsiveScaffold(
      roleTitle: 'Thu Ngân',
      roleIcon: Icons.payments_rounded,
      accentColor: _kPrimary,
      menuItems: const [
        RoleMenuItem(
          icon: Icons.dashboard_rounded,
          label: 'Tổng quan',
        ),
        RoleMenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'Thanh toán',
        ),
        RoleMenuItem(
          icon: Icons.description_rounded,
          label: 'Hóa đơn',
        ),
        RoleMenuItem(
          icon: Icons.analytics_rounded,
          label: 'Thống kê',
        ),
      ],
      pages: const [
        _CashierOverviewPage(),
        _CashierPaymentPage(),
        _CashierInvoicePage(),
        _CashierStatisticsPage(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 1: OVERVIEW (Tổng quan)
// ══════════════════════════════════════════════════════════════════════════════

class _CashierOverviewPage extends StatelessWidget {
  const _CashierOverviewPage();

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ───────────────────────────────────────────────────
          _buildPageHeader(
            title: 'Tổng Quan Thu Ngân',
            subtitle: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(DateTime.now()),
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
                    label: 'Doanh thu hôm nay',
                    value: currencyFormatter.format(15_750_000),
                    icon: Icons.monetization_on_rounded,
                    color: _kPrimary,
                  ),
                  _buildKpiCard(
                    label: 'Chờ thanh toán',
                    value: '8',
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                  ),
                  _buildKpiCard(
                    label: 'Đã thanh toán',
                    value: '42',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                  _buildKpiCard(
                    label: 'Thanh toán Online',
                    value: '15',
                    icon: Icons.phone_android_rounded,
                    color: _kAccent,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Pending Invoices Table ─────────────────────────────────────────
          _buildSectionCard(
            title: 'Hóa đơn chờ thanh toán',
            icon: Icons.pending_actions_rounded,
            child: _PendingInvoiceTable(),
          ),
          const SizedBox(height: 20),

          // ── Payment Methods Breakdown ──────────────────────────────────────
          _buildSectionCard(
            title: 'Phương thức thanh toán hôm nay',
            icon: Icons.pie_chart_rounded,
            child: _PaymentMethodSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
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
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
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
              fontSize: 20,
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

// ── Pending Invoice Mini-Table ─────────────────────────────────────────────────
class _PendingInvoiceTable extends StatelessWidget {
  _PendingInvoiceTable();

  // Placeholder data — will be replaced with real API data via Riverpod provider
  final List<Map<String, dynamic>> _mockInvoices = [
    {
      'id': 'HD-001',
      'patient': 'Nguyễn Văn A',
      'amount': 350_000,
      'time': '08:15',
      'type': 'Nội khoa',
    },
    {
      'id': 'HD-002',
      'patient': 'Trần Thị B',
      'amount': 720_000,
      'time': '08:45',
      'type': 'Ngoại khoa',
    },
    {
      'id': 'HD-003',
      'patient': 'Lê Văn C',
      'amount': 180_000,
      'time': '09:10',
      'type': 'Da liễu (AI)',
    },
    {
      'id': 'HD-004',
      'patient': 'Phạm Thị D',
      'amount': 550_000,
      'time': '09:30',
      'type': 'Tiểu đường (KNN)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _mockInvoices.map((inv) {
        return _InvoiceRow(
          invoiceId: inv['id'] as String,
          patientName: inv['patient'] as String,
          amount: inv['amount'] as int,
          time: inv['time'] as String,
          serviceType: inv['type'] as String,
        );
      }).toList(),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String invoiceId;
  final String patientName;
  final int amount;
  final String time;
  final String serviceType;

  const _InvoiceRow({
    required this.invoiceId,
    required this.patientName,
    required this.amount,
    required this.time,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
        .format(amount);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '$invoiceId • $serviceType',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            formatted,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          // Quick pay button
          ElevatedButton(
            onPressed: () {
              // TODO: Open payment dialog — will be implemented in Cashier sprint
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Xử lý thanh toán: $patientName'),
                  backgroundColor: _kPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thanh toán', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Payment Method Summary ────────────────────────────────────────────────────
class _PaymentMethodSummary extends StatelessWidget {
  const _PaymentMethodSummary();

  @override
  Widget build(BuildContext context) {
    const methods = [
      {'label': 'Tiền mặt', 'percent': 45.0, 'color': Color(0xFF1565C0)},
      {'label': 'VNPay', 'percent': 30.0, 'color': Color(0xFF0288D1)},
      {'label': 'Momo', 'percent': 15.0, 'color': Color(0xFFE91E8C)},
      {'label': 'Thẻ NH', 'percent': 10.0, 'color': Color(0xFF00897B)},
    ];

    return Column(
      children: methods.map((m) {
        final pct = m['percent'] as double;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  m['label'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: m['color'] as Color,
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pct.toInt()}%',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 2: PAYMENT PROCESSING (Thanh toán)
// ══════════════════════════════════════════════════════════════════════════════

class _CashierPaymentPage extends StatelessWidget {
  const _CashierPaymentPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xử Lý Thanh Toán',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn hóa đơn và xác nhận thanh toán cho bệnh nhân.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // ── Search Bar ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên bệnh nhân, mã hóa đơn...',
                prefixIcon:
                    const Icon(Icons.search, color: _kPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _kSurface,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Placeholder: Payment flow coming in next sprint ───────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _kPrimary.withOpacity(0.2), width: 1.5,
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.credit_card_rounded,
                    size: 64, color: _kPrimary.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Giao diện thanh toán chi tiết\nsẽ được triển khai trong sprint tiếp theo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bao gồm: QR Code VNPay / Momo, xác nhận blockchain,\nin hóa đơn PDF.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
// PAGE 3: INVOICES (Hóa đơn)
// ══════════════════════════════════════════════════════════════════════════════

class _CashierInvoicePage extends StatelessWidget {
  const _CashierInvoicePage();

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
                'Quản Lý Hóa Đơn',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download_rounded, size: 18),
                label: const Text('Xuất Excel'),
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

          // ── Status Filters ─────────────────────────────────────────────────
          Row(
            children: [
              _StatusFilterChip(
                  label: 'Tất cả', isSelected: true, color: _kPrimary),
              const SizedBox(width: 8),
              _StatusFilterChip(
                  label: 'Chờ TT', isSelected: false, color: Colors.orange),
              const SizedBox(width: 8),
              _StatusFilterChip(
                  label: 'Đã TT', isSelected: false, color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),

          // ── Invoice list placeholder ───────────────────────────────────────
          ...List.generate(5, (i) => _InvoiceListTile(index: i)),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.4)),
      onSelected: (_) {},
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final int index;
  const _InvoiceListTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final names = [
      'Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E'
    ];
    final amounts = [350000, 720000, 180000, 550000, 420000];
    final statuses = [true, true, false, true, false];

    final isPaid = statuses[index];
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

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
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color: isPaid ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[index],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'HD-${(index + 1).toString().padLeft(3, '0')} • ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(amounts[index]),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _kPrimary),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPaid ? Colors.green : Colors.orange)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'Đã TT' : 'Chờ TT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 4: STATISTICS (Thống kê)
// ══════════════════════════════════════════════════════════════════════════════

class _CashierStatisticsPage extends StatelessWidget {
  const _CashierStatisticsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống Kê Doanh Thu',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 64, color: _kPrimary.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Biểu đồ thống kê doanh thu\nsẽ được tích hợp fl_chart trong sprint tiếp theo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
