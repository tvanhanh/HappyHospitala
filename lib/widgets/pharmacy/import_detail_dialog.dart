import 'package:flutter/material.dart';

class ImportDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ImportDetailDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const Color kTextDark = Color(0xFF0F172A);
    const Color kTextMuted = Color(0xFF64748B);
    const Color kBorderColor = Color(0xFFE2E8F0);
    const Color kPrimaryBlue = Color(0xFF3EA6E9);

    // Bóc tách dữ liệu danh sách sản phẩm từ cấu trúc mới
    final List<dynamic> products = data['products'] ?? [];
    final String status = data['status'] ?? 'Hoàn thành';

    String supplierName = '---';

if (data['supplierName'] != null && data['supplierName'].toString().isNotEmpty) {
  // Ưu tiên số 1: Lấy tên đã được tra cứu chéo hoặc truyền từ ngoài vào
  supplierName = data['supplierName'].toString();
} else if (data['supplierId'] != null) {
  if (data['supplierId'] is Map) {
    // Ưu tiên số 2: Lấy từ object lồng nhau nếu backend có populate sẵn
    supplierName = data['supplierId']['supplierName'] ?? '---';
  } else {
    // Nếu quét tất cả các ngả không ra tên, lúc này mới chấp nhận hiển thị ID
    supplierName = data['supplierId'].toString();
  }
}

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600, // Độ rộng hợp lý hiển thị bảng danh sách thuốc rõ ràng
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER PHIẾU =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết phiếu nhập kho',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                      const SizedBox(height: 4),
                      // 🚀 ĐÃ SỬA: Hiển thị TÊN nhà cung cấp thay vì ID đơn thuần
                      Text(
                        'Nhà cung cấp: $supplierName',
                        style: const TextStyle(fontSize: 13, color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: kTextMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: kBorderColor, height: 1),
            const SizedBox(height: 16),

            // ================= THÔNG TIN CHUNG PHIẾU =================
            // 🚀 ĐÃ THÊM: Trường hiển thị Người lập phiếu
            _buildDetailItem('Người lập phiếu:', data['createdBy'] ?? 'Không rõ', kTextDark, kTextMuted),
            _buildDetailItem('Ghi chú phiếu:', data['note'] ?? 'Không có ghi chú', kTextDark, kTextMuted),
            _buildDetailItem(
              'Tổng tiền hóa đơn:', 
              '${(data['totalAmount'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ', 
              kTextDark, 
              kTextMuted, 
              isBold: true
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Danh sách thuốc nhập chi tiết:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark),
            ),
            const SizedBox(height: 8),

            // ================= DANH SÁCH THUỐC NHẬP (BẢNG CON) =================
            Container(
              height: 200, // Tự động xuất hiện thanh cuộn nếu quá nhiều thuốc
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),   // Tên thuốc
                    1: FlexColumnWidth(1.2), // Số lượng
                    2: FlexColumnWidth(1.8), // Đơn giá
                  },
                  children: [
                    // Tiêu đề bảng nhỏ
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC), 
                      ),
                      children: [
                        _ImportDetailTableCell('Tên thuốc', isHeader: true),
                        _ImportDetailTableCell('SL', isHeader: true),
                        _ImportDetailTableCell('Đơn giá', isHeader: true),
                      ],
                    ),
                    // Duyệt render từng dòng thuốc lẻ nằm trong mảng products
                    ...products.map((item) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
                        ),
                        children: [
                          _ImportDetailTableCell(item['medicineName'] ?? 'Không rõ'),
                          _ImportDetailTableCell('${item['quantity'] ?? 0}'),
                          _ImportDetailTableCell('${(item['importPrice'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ'),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= FOOTER (TRẠNG THÁI ĐỘNG & IN PHIẾU) =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Trạng thái hiển thị Động theo thực tế dữ liệu trả về
                _buildDynamicStatusBadge(status),

                // Nút In phiếu hành động
                OutlinedButton.icon(
                  onPressed: () {
                    // Xử lý hành động in ấn tại đây nếu cần thiết
                  },
                  icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF1E3A8A)),
                  label: const Text('In phiếu', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // Component dòng thông tin chung
  Widget _buildDetailItem(String label, String? value, Color darkColor, Color mutedColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w400)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: darkColor,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối Badge trạng thái thông minh tự đổi màu sắc theo chuỗi dữ liệu đầu vào
  Widget _buildDynamicStatusBadge(String status) {
    Color bg; Color text; IconData icon;
    
    if (status == 'Hoàn thành' || status == 'completed') {
      bg = const Color(0xFFDCFCE7); text = const Color(0xFF166534); icon = Icons.check_circle_outline;
    } else if (status == 'Đã duyệt' || status == 'approved') {
      bg = const Color(0xFFE0F2FE); text = const Color(0xFF0369A1); icon = Icons.verified_user_outlined;
    } else {
      bg = const Color(0xFFFEF3C7); text = const Color(0xFF92400E); icon = Icons.pending_actions;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: text, size: 14),
          const SizedBox(width: 4),
          Text(
            status == 'completed' ? 'Hoàn thành' : (status == 'approved' ? 'Đã duyệt' : status),
            style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// 🚀 Tách riêng Widget TableCell tĩnh để code sạch và tối ưu hiệu năng render bảng tĩnh
class _ImportDetailTableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _ImportDetailTableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          color: isHeader ? const Color(0xFF0F172A) : const Color(0xFF334155),
        ),
      ),
    );
  }
}