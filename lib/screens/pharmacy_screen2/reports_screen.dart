import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';
import '../../models/inventory_model.dart';
import '../../models/prescription_model.dart';
import '../../services/api_inventory.dart';
import '../../services/api_medicine.dart';
import '../../services/api_prescription.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ================= HỆ MÀU THƯƠNG HIỆU PHARMACARE =================
  static const Color kHeaderBlue = Color(0xFF3EA6E9);
  static const Color kPrimaryBlue = Color(0xFF3EA6E9);
  static const Color kSuccessGreen = Color(0xFF22C55E);
  static const Color kPurpleProfit = Color(0xFF8B5CF6);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kDangerRed = Color(0xFFEF4444);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);

  // Định dạng tiền tệ VND
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Hàm fetch song song toàn bộ dữ liệu từ server
  Future<Map<String, dynamic>> _fetchReportData() async {
    final futures = await Future.wait([
      ApiInventory.getInventories(),
      ApiMedicine.getAllMedicines(),
      ApiPrescription.getPendingPrescriptions(), 
    ]);

    List<InventoryModel> inventories = futures[0] as List<InventoryModel>;
    dynamic rawMedicines = futures[1];
    List<PrescriptionModel> prescriptions = futures[2] as List<PrescriptionModel>;

    // Khởi tạo map tối ưu tra cứu thông tin thuốc gốc O(1)
    Map<String, dynamic> medicineMap = {};
    if (rawMedicines != null) {
      for (var med in rawMedicines) {
        final String medId = med.id ?? med.idObj ?? '';
        if (medId.isNotEmpty) medicineMap[medId] = med;
      }
    }

    return {
      'inventories': inventories,
      'medicineMap': medicineMap,
      'prescriptions': prescriptions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const PharmaCaseDrawer(selectedMenu: "báo cáo"),
      appBar: AppBar(
        backgroundColor: kHeaderBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchReportData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('💥 Đã xảy ra lỗi tải báo cáo: ${snapshot.error}', style: const TextStyle(color: kDangerRed)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Chưa có dữ liệu thống kê.'));
          }

          final data = snapshot.data!;
          final List<InventoryModel> inventories = data['inventories'];
          final Map<String, dynamic> medicineMap = data['medicineMap'];
          // ignore: unused_local_variable
          final List<PrescriptionModel> prescriptions = data['prescriptions'];

          // ================= LOGIC XỬ LÝ TÍNH TOÁN DATA THẬT =================
          double totalImport = 0;
          double totalExport = 0;
          
          // Tính giá trị kho dựa trên dữ liệu thật
          for (var inv in inventories) {
            double price = (inv.importPrice ?? 0).toDouble();
            totalImport += (inv.currentQuantity * price);
          }

          // Phân loại nhóm thuốc dựa trên thông tin thuốc gốc trong map (Sửa lỗi .category)
          Map<String, double> categoryDistribution = {};
          for (var inv in inventories) {
            final String medId = inv.medicineId.toString();
            final originalMed = medicineMap[medId];
            
            // Lấy thuộc tính category từ đối tượng thuốc gốc một cách an toàn
            String? medCategory;
            if (originalMed != null) {
              try {
                medCategory = originalMed.category?.toString();
              } catch (_) {
                medCategory = null;
              }
            }
            
            String category = medCategory ?? 'Chưa phân loại';
            categoryDistribution[category] = (categoryDistribution[category] ?? 0) + inv.currentQuantity;
          }

          // Lọc danh sách cận hạn thật (Trong vòng 6 tháng tới)
          final DateTime now = DateTime.now();
          final DateTime sixMonthsFromNow = DateTime(now.year, now.month + 6, now.day);
          List<InventoryModel> nearExpiryItems = inventories.where((inv) {
            if (inv.expiryDate == null) return false;
            return inv.expiryDate!.isAfter(now) && inv.expiryDate!.isBefore(sixMonthsFromNow);
          }).toList();
          
          // Sắp xếp cận hạn nhất lên đầu
          nearExpiryItems.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 1200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 24),

                    // Thẻ KPI động từ DB
                    _buildKpiSection(totalImport, totalExport),
                    const SizedBox(height: 32),

                    // ROW 1: Biểu đồ cột tháng & Biểu đồ tròn Nhóm thuốc thật
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildBarChartCard()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildPieChartCard(categoryDistribution)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ROW 2: Thuốc tồn lớn & Cảnh báo hạn sử dụng thực tế (Truyền medicineMap vào)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildTopSellingCard(inventories, medicineMap)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildExpiryWarningCard(nearExpiryItems, medicineMap)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Báo cáo & Thống kê', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kTextDark)),
            SizedBox(height: 4),
            Text('Tổng hợp dữ liệu vận hành thời gian thực (2026)', style: TextStyle(fontSize: 14, color: kTextMuted)),
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

  Widget _buildKpiSection(double totalImport, double totalExport) {
    double estimatedProfit = totalImport * 0.15; // Giả định biên lợi nhuận 15%
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tổng giá trị tồn kho', currencyFormatter.format(totalImport), 'Giá trị nhập hiện tại', const Color(0xFFEFF6FF), kPrimaryBlue, Icons.inventory_2_outlined)),
        const SizedBox(width: 24),
        Expanded(child: _buildKpiCard('Tổng xuất ước tính', currencyFormatter.format(totalImport * 0.85), 'Tỷ lệ luân chuyển kho', const Color(0xFFECFDF5), kSuccessGreen, Icons.trending_up)),
        const SizedBox(width: 24),
        Expanded(child: _buildKpiCard('Lợi nhuận dự kiến', currencyFormatter.format(estimatedProfit), 'Ước tính hiệu số thương mại', const Color(0xFFF5F3FF), kPurpleProfit, Icons.grid_view_rounded)),
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
          Text(value, style: TextStyle(color: iconColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subTitle, style: const TextStyle(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xu hướng dòng hàng chu kỳ gần nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Đơn vị phân tích biên sản lượng định mức', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBarGroup('Tháng 1', 120),
                      _buildBarGroup('Tháng 2', 160),
                      _buildBarGroup('Tháng 3', 190),
                      _buildBarGroup('Tháng 4', 140),
                      _buildBarGroup('Tháng 5', 210),
                      _buildBarGroup('Tháng 6', 175),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(String month, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryBlue, kPurpleProfit],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        Text(month, style: const TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPieChartCard(Map<String, double> distribution) {
    List<Color> colorPalette = [const Color(0xFF2E5B9A), kSuccessGreen, kWarningOrange, kPurpleProfit, const Color(0xFF06B6D4), kTextMuted];
    double totalItems = distribution.values.fold(0, (sum, item) => sum + item);

    int index = 0;
    List<PieChartSectionData> sections = [];
    distribution.forEach((key, val) {
      if (index < colorPalette.length) {
        sections.add(PieChartSectionData(
          value: val,
          color: colorPalette[index],
          radius: 26,
          showTitle: false,
        ));
        index++;
      }
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(value: 1, color: Colors.grey.shade300, radius: 20, showTitle: false));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cơ cấu nhóm hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Tỷ lệ tính theo số lượng tồn hiện có', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 55,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (distribution.isEmpty)
            const Center(child: Text('Không có dữ liệu phân bổ', style: TextStyle(fontSize: 12, color: kTextMuted)))
          else
            ...(() {
              int i = 0;
              List<Widget> list = [];
              distribution.forEach((category, count) {
                if (i < colorPalette.length) {
                  double pct = totalItems > 0 ? (count / totalItems) * 100 : 0;
                  list.add(_buildPieLegendRow(category, '${pct.toStringAsFixed(1)}%', colorPalette[i]));
                  if (i < distribution.length - 1) list.add(const Divider(color: kBorderColor, height: 12));
                  i++;
                }
              });
              return list;
            }()),
        ],
      ),
    );
  }

  // Nhận thêm medicineMap để tra cứu đơn vị tính (Sửa lỗi .unit)
  Widget _buildTopSellingCard(List<InventoryModel> inventories, Map<String, dynamic> medicineMap) {
    List<InventoryModel> topInventory = List.from(inventories);
    topInventory.sort((a, b) => b.currentQuantity.compareTo(a.currentQuantity));
    List<InventoryModel> displayList = topInventory.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bảng phân tích cơ số thuốc chủ lực', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Top sản phẩm có lượng lưu trữ cao nhất hệ thống', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderColor, width: 1))),
                children: ['#', 'Tên thuốc', 'Tồn kho hiện tại', 'Đơn giá nhập'].map((title) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMuted, fontSize: 13)),
                  );
                }).toList(),
              ),
              if (displayList.isEmpty)
                const TableRow(children: [SizedBox(), Padding(padding: EdgeInsets.all(16), child: Text('Không có dữ liệu')), SizedBox(), SizedBox()])
              else
                ...displayList.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  var item = entry.value;
                  
                  // Lấy unit từ thuốc gốc dựa vào medicineId
                  final originalMed = medicineMap[item.medicineId.toString()];
                  String unitText = 'đơn vị';
                  if (originalMed != null) {
                    try {
                      unitText = originalMed.unit?.toString() ?? 'đơn vị';
                    } catch (_) {}
                  }

                  return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: idx == 1 ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                          child: Text('$idx', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: idx == 1 ? kWarningOrange : kTextMuted)),
                        ),
                      ),
                      Text(item.medicineName ?? 'Không rõ tên', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13)),
                      Text('${item.currentQuantity} $unitText', style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(currencyFormatter.format(item.importPrice ?? 0), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  // Nhận thêm medicineMap để tra cứu đơn vị tính (Sửa lỗi .unit)
  Widget _buildExpiryWarningCard(List<InventoryModel> nearExpiryItems, Map<String, dynamic> medicineMap) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cảnh báo hạn sử dụng thực tế', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 4),
          const Text('Sản phẩm cận hạn hoặc quá hạn hệ thống ghi nhận', style: TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 24),
          if (nearExpiryItems.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('🎉 Tuyệt vời! Không có lô thuốc nào sắp hết hạn.', style: TextStyle(color: kSuccessGreen, fontSize: 13))),
            )
          else
            ...nearExpiryItems.take(4).map((item) {
              String dateStr = item.expiryDate != null ? DateFormat('dd/MM/yyyy').format(item.expiryDate!) : 'Không rõ';
              
              // Lấy unit từ thuốc gốc dựa vào medicineId
              final originalMed = medicineMap[item.medicineId.toString()];
              String unitText = '';
              if (originalMed != null) {
                try {
                  unitText = originalMed.unit?.toString() ?? '';
                } catch (_) {}
              }

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
                            Text(item.medicineName ?? 'Thuốc chưa đặt tên', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Tồn: ${item.currentQuantity} $unitText — Lô: ${item.batchNumber ?? 'N/A'}', style: const TextStyle(color: kTextMuted, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HSD: $dateStr', style: TextStyle(color: kDangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
                                const Text('Cần lưu ý', style: TextStyle(color: kWarningOrange, fontSize: 11, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
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

  Widget _buildPieLegendRow(String title, String percent, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ],
        ),
        Text(percent, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}