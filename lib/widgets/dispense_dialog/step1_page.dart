import 'package:flutter/material.dart';
import 'dispense_medicine_dialog.dart'; // Import để dùng chung hệ màu hằng số

class Step1Page extends StatelessWidget {
  final Map<String, dynamic> prescription;
  final List medicines;
  final String dateDisplay;

  const Step1Page({super.key, required this.prescription, required this.medicines, required this.dateDisplay,});

  @override
  Widget build(BuildContext context) {
    print("DỮ LIỆU ĐƠN THUỐC THỰC TẾ: ${prescription.toString()}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner thông tin
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kPrimaryBlue, size: 20),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Kiểm tra thông tin đơn thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1))),
                  SizedBox(height: 2),
                  Text('Xác nhận thông tin bệnh nhân và danh sách thuốc', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Khối thông tin bệnh nhân
        const Text('Thông tin bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetaRow('Họ tên:', prescription['patientName'] ?? 'N/A', isBoldValue: true),
              const SizedBox(height: 10),
              _buildMetaRow('Bác sĩ:', prescription['doctorName'] ?? 'N/A'),
              const SizedBox(height: 10),
             _buildMetaRow('Ngày kê đơn:', dateDisplay),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Khối Danh sách thuốc
        Text('Danh sách thuốc (${medicines.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
        const SizedBox(height: 12),
        ...medicines.map((med) {
          bool isOutOfStock = med['stock'] == 0;
          Color currentItemColor = isOutOfStock ? kDangerRed : kBorderColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOutOfStock ? kDangerRed.withOpacity(0.8) : kBorderColor, width: isOutOfStock ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
                const SizedBox(height: 4),
                Text(med['usage'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 40,
                      child: TextFormField(
                        initialValue: med['qty'],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: med['quantity'],
                          labelStyle: TextStyle(color: isOutOfStock ? kDangerRed : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: currentItemColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: currentItemColor)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: isOutOfStock ? kDangerRed : kSuccessGreen, borderRadius: BorderRadius.circular(20)),
                      child: Text('Kho: ${med['stock']} viên', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Lô: ${med['batch']}  •  HSD: ${med['exp']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    )
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      children: [
        Text('$label ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: kTextDark, fontSize: 14, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}