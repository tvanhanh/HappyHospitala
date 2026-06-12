import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // THÊM THƯ VIỆN NÀY ĐỂ VẼ BIỂU ĐỒ TRÒN CHUẨN 100%
import '../../widgets/pharmacy/pharmaCase_drawer.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ================= HỆ MÀU THƯƠNG HIỆU PHARMACARE (ĐỒNG BỘ) =================
  static const Color kHeaderBlue = Color(0xFF3EA6E9);
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kPurpleProfit = Color(0xFF8B5CF6);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kDangerRed = Color(0xFFEF4444);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const PharmaCaseDrawer(selectedMenu: "Báo cáo"),

      // ================= 1. MENU HEADER HỆ THỐNG =================
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF64B5F6), shape: BoxShape.circle),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PharmaCare System', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Hệ thống quản lý nhà thuốc thông minh', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF64B5F6),
                    child: Text('DS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10),
                  Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ================= 2. BODY CHÍNH CỦA TRANG BÁO CÁO =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SizedBox(
            width: 1200, // GIỮ NGUYÊN FORM HIỂN THỊ CŨ 1200
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 24),

                // 3 Thẻ KPI Thống Kê Tài Chính Đầu Trang
                _buildKpiSection(),
                const SizedBox(height: 32),

                // ROW 1: Biểu đồ cột bên trái & Biểu đồ tròn phân bổ nhóm thuốc bên phải
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildBarChartCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildPieChartCard()),
                  ],
                ),
                const SizedBox(height: 32),

                // ROW 2: Danh sách Top thuốc bán chạy bên trái & Cảnh báo hạn sử dụng bên phải
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildTopSellingCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildExpiryWarningCard()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tiêu đề trang & Nút xuất file
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Báo cáo & Thống kê', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark)),
            SizedBox(height: 4),
            Text('Tổng hợp nhập xuất 6 tháng đầu năm 2026', style: TextStyle(fontSize: 14, color: kTextMuted)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18, color: kTextDark),
          label: const Text('Xuất báo cáo', style: TextStyle(color: kTextDark, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: kBorderColor)),
          ),
        ),
      ],
    );
  }

  // Khối 3 Thẻ thống kê KPI tài chính
  Widget _buildKpiSection() {
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tổng nhập kho', '122.3M đ', '6 tháng đầu năm', const Color(0xFFEFF6FF), kPrimaryBlue, Icons.trending_down)),
        const SizedBox(width: 24),
        Expanded(child: _buildKpiCard('Tổng xuất kho', '97.1M đ', '6 tháng đầu năm', const Color(0xFFECFDF5), kSuccessGreen, Icons.trending_up)),
        const SizedBox(width: 24),
        Expanded(child: _buildKpiCard('Lợi nhuận ước tính', '11.5M đ', 'Sau chi phí vận hành', const Color(0xFFF5F3FF), kPurpleProfit, Icons.grid_view_rounded)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String subTitle, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: iconColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subTitle, style: const TextStyle(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // Khối Biểu đồ cột Nhập/Xuất/Lợi nhuận
  Widget _buildBarChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập / Xuất / Lợi nhuận theo tháng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Đơn vị: triệu đồng', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('26M', style: TextStyle(color: kTextMuted, fontSize: 11)),
                    Text('17M', style: TextStyle(color: kTextMuted, fontSize: 11)),
                    Text('9M', style: TextStyle(color: kTextMuted, fontSize: 11)),
                    Text('0M', style: TextStyle(color: kTextMuted, fontSize: 11)),
                    Text('-9M', style: TextStyle(color: kTextMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBarGroup('T1', 140),
                      _buildBarGroup('T2', 170),
                      _buildBarGroup('T3', 120),
                      _buildBarGroup('T4', 210),
                      _buildBarGroup('T5', 150),
                      _buildBarGroup('T6', 190),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Nhập kho', kPrimaryBlue),
              const SizedBox(width: 24),
              _buildLegendItem('Xuất kho', kSuccessGreen),
              const SizedBox(width: 24),
              _buildLegendItem('Lợi nhuận', kPurpleProfit),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBarGroup(String month, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(color: kPurpleProfit, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 12),
        Text(month, style: const TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Khối Biểu đồ tròn Phân bổ nhóm thuốc (Đã nâng cấp bằng FL_CHART lớn và khép kín 100%)
  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân bổ nhóm thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Tỷ lệ doanh số xuất', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 32),
          
          // Biểu đồ tròn khép kín 100% với kích thước lớn hơn (Đường kính 200)
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2, // Khoảng cách nhỏ giữa các lát cắt cho đẹp mắt
                  centerSpaceRadius: 65, // Tạo khoảng rỗng ở giữa (Donut Chart)
                  startDegreeOffset: -90, // Bắt đầu góc vẽ từ đỉnh trên cùng
                  sections: [
                    PieChartSectionData(value: 28, color: const Color(0xFF2E5B9A), radius: 24, showTitle: false),
                    PieChartSectionData(value: 22, color: kSuccessGreen, radius: 24, showTitle: false),
                    PieChartSectionData(value: 18, color: kWarningOrange, radius: 24, showTitle: false),
                    PieChartSectionData(value: 14, color: kPurpleProfit, radius: 24, showTitle: false),
                    PieChartSectionData(value: 12, color: const Color(0xFF06B6D4), radius: 24, showTitle: false),
                    PieChartSectionData(value: 6, color: const Color(0xFF64748B), radius: 24, showTitle: false),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildPieLegendRow('Kháng sinh', '28%', const Color(0xFF2E5B9A)),
          const Divider(color: kBorderColor, height: 16),
          _buildPieLegendRow('Giảm đau', '22%', kSuccessGreen),
          const Divider(color: kBorderColor, height: 16),
          _buildPieLegendRow('Tim mạch', '18%', kWarningOrange),
          const Divider(color: kBorderColor, height: 16),
          _buildPieLegendRow('Hô hấp', '14%', kPurpleProfit),
          const Divider(color: kBorderColor, height: 16),
          _buildPieLegendRow('Tiểu đường', '12%', const Color(0xFF06B6D4)),
          const Divider(color: kBorderColor, height: 16),
          _buildPieLegendRow('Khác', '6%', const Color(0xFF64748B)),
        ],
      ),
    );
  }

  // Khối Danh sách "Top thuốc bán chạy"
  Widget _buildTopSellingCard() {
    final List<Map<String, dynamic>> topProducts = [
      {'rank': '1', 'name': 'Amoxicillin 500mg', 'qty': '1,280 viên', 'revenue': '2.304.000 đ', 'pct': 0.26, 'color': const Color(0xFF2E5B9A)},
      {'rank': '2', 'name': 'Paracetamol 500mg', 'qty': '980 viên', 'revenue': '490.000 đ', 'pct': 0.055, 'color': kSuccessGreen},
      {'rank': '3', 'name': 'Ibuprofen 400mg', 'qty': '760 viên', 'revenue': '1.672.000 đ', 'pct': 0.189, 'color': kWarningOrange},
      {'rank': '4', 'name': 'Loratadine 10mg', 'qty': '640 viên', 'revenue': '1.024.000 đ', 'pct': 0.115, 'color': kPurpleProfit},
      {'rank': '5', 'name': 'Atorvastatin 20mg', 'qty': '520 viên', 'revenue': '3.380.000 đ', 'pct': 0.381, 'color': kDangerRed},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top thuốc bán chạy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Theo doanh số 6 tháng đầu năm 2026', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.4),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderColor, width: 1))),
                children: ['#', 'Tên thuốc', 'Số lượng bán', 'Doanh thu', 'Tỷ trọng'].map((title) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMuted, fontSize: 13)),
                  );
                }).toList(),
              ),
              ...topProducts.map((prod) {
                return TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: prod['rank'] == '1' ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                        child: Text(prod['rank'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: prod['rank'] == '1' ? kWarningOrange : kTextMuted)),
                      ),
                    ),
                    Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13)),
                    Text(prod['qty'], style: const TextStyle(color: kTextDark, fontSize: 13)),
                    Text(prod['revenue'], style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13)),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: prod['pct'], minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), color: prod['color']),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(prod['pct'] * 100).toStringAsFixed(1)}%', style: const TextStyle(color: kTextMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Khối "Cảnh báo hạn sử dụng"
  Widget _buildExpiryWarningCard() {
    final List<Map<String, dynamic>> warnings = [
      {'name': 'Amoxicillin 500mg', 'detail': '1200 Viên — Lô BN2024001', 'hsd': '2026-08-15'},
      {'name': 'Paracetamol 500mg', 'detail': '85 Viên — Lô BN2024002', 'hsd': '2025-12-31'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cảnh báo hạn sử dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Thuốc hết hạn hoặc sắp hết hạn trong 6 tháng tới', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 24),
          ...warnings.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.warning_amber_rounded, color: kWarningOrange, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(item['detail'], style: const TextStyle(color: kTextMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('HSD: ${item['hsd']}', style: const TextStyle(color: kDangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('Ưu tiên bán trước', style: TextStyle(color: kSuccessGreen, fontSize: 11, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Các Widget phụ trợ vẽ giao diện
  Widget _buildPieLegendRow(String title, String percent, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(percent, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}