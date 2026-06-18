import 'package:flutter/material.dart';

class InventoryDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const InventoryDetailDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ================= HỆ MÀU SẮC ĐỒNG BỘ PHARMACARE =================
    const Color kPrimaryBlue = Color(0xFF3EA6E9);
    const Color kSuccessGreen = Color(0xFF22C55E);
    const Color kWarningOrange = Color(0xFFF59E0B);
    const Color kDangerRed = Color(0xFFEF4444);
    const Color kBorderColor = Color(0xFFE2E8F0);
    const Color kTextDark = Color(0xFF0F172A);
    const Color kTextMuted = Color(0xFF64748B);
    const Color kBgLight = Color(0xFFF8FAFC);

    // ================= BÓC TÁCH DỮ LIỆU ĐỒNG BỘ CHUẨN =================
    final String name = data['name'] ?? data['medicineName'] ?? 'Chưa rõ tên';
    final String id = data['medicineId'] ?? data['id'] ?? data['_id'] ?? 'N/A';
    final String batchNumber = data['batchNumber'] ?? data['batch_number'] ?? 'KHÔNG SỐ LÔ'; // 🔥 ĐÃ SỬA: Lấy đúng số lô thực tế
    final String brand = data['manufacturer'] ?? data['brand'] ?? 'N/A';
    final String activeIngredient = data['activeIngredient'] ?? data['active_ingredient'] ?? 'N/A';
    final String group = data['group'] ?? data['category'] ?? 'Khác';
    
    final int stock = (data['stock'] ?? data['quantity'] ?? data['currentQuantity'] ?? 0).toInt();
    final int minStock = (data['min_stock'] ?? data['minStock'] ?? 0).toInt();
    final String unit = data['unit'] ?? 'Viên';
    
    final double importPrice = (data['import_price'] ?? data['importPrice'] ?? 0).toDouble();
    final double exportPrice = (data['selling_price'] ?? data['export_price'] ?? data['exportPrice'] ?? 0).toDouble();
    final String expiryDate = data['expiry_date'] ?? data['expiryDate'] ?? 'N/A';
    final String status = data['status'] ?? 'Còn hàng';

    // Tính toán lợi nhuận (%) chi tiết
    String profitPercent = '0%';
    if (importPrice > 0) {
      double profitValue = ((exportPrice - importPrice) / importPrice) * 100;
      profitPercent = '${profitValue.toStringAsFixed(1)}%';
    }

    // 🔥 ĐÃ SỬA: Hàm định dạng tiền tệ VNĐ xử lý chuẩn kiểu double
    String formatMoney(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
      ) + ' đ';
    }

    // Xác định cấu hình màu sắc linh hoạt theo trạng thái thực tế của thuốc
    Color statusBgColor = const Color(0xFFDCFCE7);
    Color statusTextColor = const Color(0xFF166534);
    IconData warningIcon = Icons.check_circle_outline;
    String warningMessage = 'An toàn: Số lượng tồn kho đảm bảo định mức.';
    Color warningColor = kSuccessGreen;

    if (status == 'Sắp hết' || stock <= minStock) {
      statusBgColor = const Color(0xFFFFFBEB);
      statusTextColor = kWarningOrange;
      warningIcon = Icons.report_problem_outlined;
      warningMessage = 'Cảnh báo: Số lượng tồn đang dưới mức tối thiểu!';
      warningColor = kWarningOrange;
    } 
    if (status == 'Hết hàng' || stock == 0) {
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = kDangerRed;
      warningIcon = Icons.cancel_outlined;
      warningMessage = 'Nguy hiểm: Thuốc đã hết hàng hoàn toàn trong kho!';
      warningColor = kDangerRed;
    }
    if (status == 'Hết hạn') {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = kTextDark;
      warningIcon = Icons.hourglass_disabled_outlined;
      warningMessage = 'Nghiêm trọng: Lô thuốc này đã quá hạn sử dụng!';
      warningColor = kDangerRed;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 24,
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. TIÊU ĐỀ DIALOG =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication_liquid, color: kPrimaryBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã thuốc: $id',
                              style: const TextStyle(fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: kBorderColor, height: 1),
            const SizedBox(height: 16),

            // ================= 2. PHẦN THÂN PHÉP CUỘN =================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.info_outline, 'Thông tin thuốc', kPrimaryBlue),
                    _buildInfoCard(bgColor: kBgLight, children: [
                      _buildDetailGridRow('Hoạt chất:', activeIngredient, 'Nhóm thuốc:', group, kTextDark, kTextMuted),
                      const SizedBox(height: 10),
                      _buildDetailGridRow('Nhà sản xuất:', brand, 'Xuất xứ:', 'Chính hãng', kTextDark, kTextMuted),
                      const SizedBox(height: 10),
                      _buildDetailGridRow('Đơn vị tính:', unit, '', '', kTextDark, kTextMuted),
                    ]),
                    const SizedBox(height: 20),

                    _buildSectionTitle(Icons.analytics_outlined, 'Tồn kho & Giá', kPrimaryBlue),
                    _buildInfoCard(bgColor: kBgLight, children: [
                      _buildDetailGridRow(
                        'Số lượng tồn:', '$stock $unit', 
                        'Tồn tối thiểu:', '$minStock $unit', 
                        kTextDark, kTextMuted, 
                        leftValueColor: (stock <= minStock) ? kWarningOrange : kTextDark, 
                        isLeftBold: true
                      ),
                      const SizedBox(height: 10),
                      _buildDetailGridRow(
                        'Giá nhập:', formatMoney(importPrice), 
                        'Giá bán:', formatMoney(exportPrice), 
                        kTextDark, kTextMuted, 
                        isRightBold: true
                      ),
                      const SizedBox(height: 10),
                      _buildDetailGridRow('Lợi nhuận:', profitPercent, '', '', kTextDark, kTextMuted, leftValueColor: kSuccessGreen, isLeftBold: true),
                    ]),
                    const SizedBox(height: 20),

                    _buildSectionTitle(Icons.warehouse_outlined, 'Lưu trữ & Hạn dùng', kPrimaryBlue),
                    _buildInfoCard(bgColor: kBgLight, children: [
                      _buildDetailGridRow('Vị trí kho:', 'Khu A', 'Số lô:', batchNumber, kTextDark, kTextMuted),
                      const SizedBox(height: 10),
                      _buildDetailGridRow(
                        'Hạn sử dụng:', expiryDate, 
                        '', '', 
                        kTextDark, kTextMuted, 
                        leftValueColor: (status == 'Hết hạn') ? kDangerRed : kTextDark, 
                        isLeftBold: true
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(color: kBorderColor, height: 1),
            const SizedBox(height: 16),

            // ================= 3. FOOTER TRẠNG THÁI & CẢNH BÁO =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(warningIcon, color: warningColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warningMessage,
                          style: TextStyle(color: warningColor, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusTextColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: themeColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required Color bgColor, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailGridRow(
    String leftLabel, String leftValue, 
    String rightLabel, String rightValue, 
    Color darkColor, Color mutedColor, 
    {Color? leftValueColor, bool isLeftBold = false, bool isRightBold = false}
  ) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel, style: TextStyle(color: mutedColor, fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  leftValue,
                  style: TextStyle(
                    color: leftValueColor ?? darkColor,
                    fontSize: 13,
                    fontWeight: isLeftBold ? FontWeight.bold : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: rightLabel.isEmpty 
              ? const SizedBox.shrink() 
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rightLabel, style: TextStyle(color: mutedColor, fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rightValue,
                        style: TextStyle(
                          color: darkColor,
                          fontSize: 13,
                          fontWeight: isRightBold ? FontWeight.bold : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}