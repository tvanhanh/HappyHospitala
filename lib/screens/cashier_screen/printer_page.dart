import 'package:flutter/material.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  String selectedPrinter = 'HP LaserJet Pro - Quầy thu ngân 1';
  String selectedPaperSize = 'K80 (80mm)';
  bool autoPrint = true;
  bool printCopy = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cấu hình máy in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        const Text('Máy in mặc định', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedPrinter,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(),
          items: const [
            DropdownMenuItem(value: 'HP LaserJet Pro - Quầy thu ngân 1', child: Text('HP LaserJet Pro - Quầy thu ngân 1', style: TextStyle(fontSize: 14))),
          ],
          onChanged: (val) => setState(() => selectedPrinter = val!),
        ),
        const SizedBox(height: 20),

        const Text('Khổ giấy hóa đơn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedPaperSize,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(),
          items: const [
            DropdownMenuItem(value: 'K80 (80mm)', child: Text('K80 (80mm)', style: TextStyle(fontSize: 14))),
          ],
          onChanged: (val) => setState(() => selectedPaperSize = val!),
        ),
        const SizedBox(height: 20),

        _buildSwitchTile('Tự động in hóa đơn sau thanh toán', 'In ngay sau khi hoàn tất thanh toán', autoPrint, (val) => setState(() => autoPrint = val)),
        _buildSwitchTile('In bản sao cho bệnh nhân', 'In 2 liên: 1 cho phòng khám, 1 cho bệnh nhân', printCopy, (val) => setState(() => printCopy = val)),
        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.print_outlined, color: Colors.black87, size: 18),
              SizedBox(width: 8),
              Text('In thử hóa đơn mẫu', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
      child: SwitchListTile(
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF070412),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}