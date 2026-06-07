import 'package:flutter/material.dart';

class PaymentForm extends StatefulWidget {
  const PaymentForm({super.key});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  String selectedMethod = 'Tiền mặt';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 500, 
      elevation: 0,
      shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomRight: Radius.circular(16)
      ),
    ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER CỦA PANEL
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thanh toán hóa đơn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // 2. NỘI DUNG CHI TIẾT (CUỘN MƯỢT MÀ)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Khối thông tin bệnh nhân hành chính
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BỆNH NHÂN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        const Text('Nguyễn Văn An (BN001)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text('Thời gian đến: 09:30', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chi tiết dịch vụ
                  const Text('CHI TIẾT DỊCH VỤ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  _buildRowItem('Khám tổng quát', '200.000đ'),
                  _buildRowItem('Xét nghiệm máu', '150.000đ'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider( thickness: 1,color: Color(0xFFE5E7EB),),
                  ),
                  _buildRowItem('Tổng dịch vụ:', '350.000đ', isBold: true),
                  const SizedBox(height: 24),

                  // Chi tiết thuốc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('CHI TIẾT THUỐC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text('2 loại thuốc', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMedicineItem('Paracetamol 500mg', 'Thuốc • 500đ/Viên', '10 Viên', '10.000đ'),
                  _buildMedicineItem('Vitamin C 1000mg', 'Thuốc • 1.500đ/Viên', '10 Viên', '15.000đ'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider( thickness: 1,color: Color(0xFFE5E7EB),),
                  ),
                  _buildRowItem('Tổng tiền thuốc:', '25.000đ', isBold: true, color: Colors.orange),
                  const SizedBox(height: 24),

                  // Phương thức thanh toán
                  const Text('PHƯƠNG THỨC THANH TOÁN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMethodBox('Tiền mặt', Icons.payments_outlined),
                      const SizedBox(width: 12),
                      _buildMethodBox('Thẻ', Icons.credit_card),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (selectedMethod == 'Tiền mặt') ...[
                    const Text('Tiền khách đưa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nhập số tiền...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Khối tổng chốt hóa đơn
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070412).withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildRowItem('Tổng chi phí dịch vụ:', '350.000đ', fontSize: 13),
                        _buildRowItem('Tổng chi phí thuốc:', '25.000đ', fontSize: 13),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Color(0xFFE2E8F0))),
                        _buildRowItem('TỔNG THANH TOÁN:', '375.000đ', isBold: true, fontSize: 16, color: const Color(0xFF070412)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. THANH HÀNH ĐỘNG CỐ ĐỊNH DƯỚI ĐÁY
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF1E293B)),
                    label: const Text('In hóa đơn', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Đã xác nhận và xuất hóa đơn thành công!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF070412),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRowItem(String title, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w400, color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(String title, String subTitle, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
              Text(subTitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          Text(qty, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildMethodBox(String method, IconData icon) {
    bool isSelected = selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF070412) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF070412) : const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(method, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF070412) : const Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }
}