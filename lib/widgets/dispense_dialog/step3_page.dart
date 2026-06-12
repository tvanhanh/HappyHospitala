import 'package:flutter/material.dart';
import 'dispense_medicine_dialog.dart'; // Import để dùng chung hệ màu hằng số

class Step3Page extends StatefulWidget {
  final String patientName;
  final int totalMedicines; 
  final bool isInNhanThuoc;
  final bool isLuuBlockchain;
  final ValueChanged<bool> onInNhanThuocChanged;
  final ValueChanged<bool> onLuuBlockchainChanged;

  const Step3Page({
    super.key, 
    required this.patientName,
    required this.totalMedicines,
    required this.isInNhanThuoc,
    required this.isLuuBlockchain,
    required this.onInNhanThuocChanged,
    required this.onLuuBlockchainChanged,
  });

  @override
  State<Step3Page> createState() => _Step3PageState();
}

class _Step3PageState extends State<Step3Page> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hộp thông báo màu vàng cảnh báo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Xác nhận cấp phát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E))),
                  SizedBox(height: 2),
                  Text('Vui lòng kiểm tra kỹ trước khi xác nhận', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Cặp thẻ thông tin tóm tắt
        Row(
          children: [
            _buildSummaryCard('Bệnh nhân', widget.patientName),
            const SizedBox(width: 16),
            _buildSummaryCard('Số lượng thuốc', '${widget.totalMedicines} loại'), 
          ],
        ),
        const SizedBox(height: 32),

        // Switch nút bấm In nhãn thuốc
        Row(
          children: [
            Switch(
              value: widget.isInNhanThuoc,
              activeColor: Colors.white,
              activeTrackColor: kPrimaryBlue,
              onChanged: widget.onInNhanThuocChanged,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('In nhãn thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
                const SizedBox(height: 2),
                Text('Tự động in nhãn hướng dẫn sử dụng', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),

        // Switch nút bấm Blockchain
        Row(
          children: [
            Switch(
              value: widget.isLuuBlockchain,
              activeColor: Colors.white,
              activeTrackColor: kPrimaryBlue,
              onChanged: widget.onLuuBlockchainChanged,
            ),
            const SizedBox(width: 12),
            const Icon(Icons.shield_outlined, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lưu hash lên Blockchain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
                const SizedBox(height: 2),
                Text('Đảm bảo tính toàn vẹn dữ liệu đơn thuốc', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark)),
          ],
        ),
      ),
    );
  }
}