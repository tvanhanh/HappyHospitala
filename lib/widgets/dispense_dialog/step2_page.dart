import 'package:flutter/material.dart';
import 'dispense_medicine_dialog.dart'; // Import để dùng chung hệ màu hằng số

class Step2Page extends StatelessWidget {
  final List medicines;

  const Step2Page({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner kiểm tra AI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: kSuccessGreen, size: 22),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 Kiểm tra tương tác thuốc bằng AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534))),
                  SizedBox(height: 2),
                  Text('Hệ thống AI đã phân tích - Không phát hiện tương tác nguy hiểm', style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Hộp kết quả chi tiết
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: kSuccessGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kết quả kiểm tra tương tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark)),
                      SizedBox(height: 2),
                      Text('Các thuốc trong đơn có thể sử dụng đồng thời', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: kBorderColor, height: 1),
              const SizedBox(height: 20),
              const Text('Danh sách đã kiểm tra:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
              const SizedBox(height: 16),
              ...medicines.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: kSuccessGreen, size: 18),
                    const SizedBox(width: 10),
                    Text(med['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark)),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Khối lưu ý hệ thống phía dưới cùng
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.info, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF0369A1)),
                    children: [
                      TextSpan(text: '💡 Lưu ý: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Hệ thống AI chỉ mang tính chất tham khảo. Dược sĩ cần kiểm tra kỹ trước khi cấp phát.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}