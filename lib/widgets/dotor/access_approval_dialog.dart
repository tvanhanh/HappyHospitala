import 'package:flutter/material.dart';

class AccessApprovalDialog extends StatefulWidget {
  final String doctorName;
  final String hospitalName;
  final int recordCount;
  final Function(String note) onConfirm;

  const AccessApprovalDialog({
    Key? key,
    required this.doctorName,
    required this.hospitalName,
    required this.recordCount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AccessApprovalDialog> createState() => _AccessApprovalDialogState();
}

class _AccessApprovalDialogState extends State<AccessApprovalDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Nền trắng chuẩn y tế
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TIÊU ĐỀ ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF137333), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Xác nhận cho phép truy cập",
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 20),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Bác sĩ sẽ nhận token truy cập có thời hạn 24 giờ để đọc hồ sơ.",
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            
            // --- BOX THÔNG TIN BÁC SĨ & BỆNH VIỆN (NỀN XÁM NHẠT) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), 
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDF2F7), width: 1), // 🔥 ĐÃ SỬA LỖI MÀU Ở ĐÂY
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Bác sĩ:", widget.doctorName),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFE5E7EB), height: 1),
                  ),
                  _buildInfoRow("Bệnh viện:", widget.hospitalName),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFE5E7EB), height: 1),
                  ),
                  _buildInfoRow("Số hồ sơ:", "${widget.recordCount} hồ sơ"),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // --- KHỐI NHẬP GHI CHÚ ---
            const Text(
              "Ghi chú (tuỳ chọn)", 
              style: TextStyle(color: Color(0xFF374151), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
              decoration: InputDecoration(
                hintText: "Nhập ghi chú thêm cho bác sĩ...",
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),
            
            // --- HÀNG NÚT BẤM ĐIỀU HƯỚNG ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Hủy", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    widget.onConfirm(_noteController.text.trim()); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Đồng ý cho phép", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}