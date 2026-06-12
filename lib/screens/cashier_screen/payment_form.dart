import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../models/prescription_model.dart'; 
import '../../models/bill_model.dart';
import '../../services/api_bill.dart';
import '../../services/api_prescription.dart';



class PaymentForm extends StatefulWidget {
  final PrescriptionModel? prescription; 

  const PaymentForm({super.key, this.prescription});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  String selectedMethod = 'Tiền mặt';
  final TextEditingController _cashController = TextEditingController();
  
  // Hàm trợ giúp để định dạng số tiền thành chuỗi "100,000đ"
  String _formatMoney(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}đ';
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prescription == null) {
      return const Drawer(
        width: 500,
        child: Center(child: Text('Không tìm thấy dữ liệu đơn thuốc!')),
      );
    }

    final PrescriptionModel p = widget.prescription!;
    
    String patientName = p.patientName; 
    String patientId = p.patientId;     
    String timeArrived = "Hôm nay"; 
    
    List<dynamic> services = []; // Mảng dịch vụ (nếu có)
    List<PrescribedMedicine> medicines = p.medicines;

    int totalServicesPrice = 0; 
    
    int totalMedicinesPrice = medicines.fold(0, (sum, item) {
      int qty = int.tryParse(item.quantity) ?? 0;
      int pricePerUnit = 0;
      if (item.sellingPrice != null) {
        pricePerUnit = item.sellingPrice!;
      }
      String activeUnit = 'Đơn vị'; 
         if (item.unit != null && item.unit!.isNotEmpty) {
             activeUnit = item.unit!;
                    }
      
      return sum + (pricePerUnit * qty);
    });
    
    // Nếu Backend đã tính sẵn tổng p.totalPrice thì lấy, ngược lại tự cộng tổng
    int finalTotalPrice = (p.totalPrice != null && p.totalPrice! > 0) 
        ? p.totalPrice! 
        : (totalServicesPrice + totalMedicinesPrice);

void _handlePaymentConfirm(PrescriptionModel prescription, int totalServices, int totalMedicines, int finalTotal) async {
 String nowRealTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
  final billData = BillModel(
    patientId: prescription.patientId,
    patientName: prescription.patientName,
    timeArrived: nowRealTime,
    paymentMethod: selectedMethod,
    cashGiven: int.tryParse(_cashController.text) ?? 0,
    totalServicesPrice: totalServices,
    totalMedicinesPrice: totalMedicines,
    finalTotalPrice: finalTotal,
    medicines: prescription.medicines.map((med) {
      return BillMedicineItem(
        id: med.medicineId ?? '',
        name: med.name,
        quantity: med.quantity,
        sellingPrice: med.sellingPrice ?? 0,
        unit: (med.unit != null && med.unit!.isNotEmpty) ? med.unit! : 'Đơn vị',
      );
    }).toList(),
    services: [], 
  );
  Map<String, dynamic> jsonPayload = billData.toJson();
  
  print("DEBUG BILL JSON: $jsonPayload"); 

  try {
    final savedBill = await ApiBill.createBill(billData);
    if (!mounted) return;

    if (savedBill != null) {
      if (prescription.id != null) {
    await ApiPrescription.updatePrescriptionStatus(prescription.id!, 'paid');
  }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Thanh toán thành công ${_formatMoney(finalTotal)} cho bệnh nhân ${prescription.patientName}!'), 
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Thông báo nếu Server trả về lỗi (Ví dụ: statusCode không phải 200/201)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lưu hóa đơn thất bại. Vui lòng kiểm tra lại dữ liệu!'), 
          backgroundColor: Colors.amber,
        ),
      );
    }

  } catch (e) {
    // Bắt các lỗi mất kết nối mạng, lỗi Server sập (Crash 500)
    if (!mounted) return;
    print("💥 Lỗi khi thực hiện bấm nút xác nhận thanh toán: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💥 Đã xảy ra lỗi kết nối: $e'), 
        backgroundColor: Colors.red,
      ),
    );
  }
 
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('🎉 Thanh toán thành công ${_formatMoney(finalTotal)} cho bệnh nhân ${prescription.patientName}!'), 
      backgroundColor: Colors.green,
    ),
  );
}
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

          // 2. NỘI DUNG CHI TIẾT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Khối thông tin bệnh nhân
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
                        Text('$patientName ($patientId)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text('Thời gian đến: $timeArrived', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CHI TIẾT DỊCH VỤ
                  const Text('CHI TIẾT DỊCH VỤ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  if (services.isEmpty)
                    const Text('Không có dịch vụ nào chỉ định', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  
                  ...services.map((svc) {
                    int price = svc['sellingPrice'] ?? 0;
                    return _buildRowItem(
                      svc['name'] ?? 'Dịch vụ chỉ định', 
                      _formatMoney(price)
                    );
                  }).toList(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _buildRowItem('Tổng dịch vụ:', _formatMoney(totalServicesPrice), isBold: true),
                  const SizedBox(height: 24),

                  // CHI TIẾT THUỐC
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CHI TIẾT THUỐC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text('${medicines.length} loại thuốc', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (medicines.isEmpty)
                    const Text('Đơn thuốc này không kèm thuốc', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  
                  // 🟢 SỬA LỖI HIỂN THỊ TIỀN TỪNG VIÊN VÀ TỔNG TIỀN ĐƠN VỊ THUỐC TẠI ĐÂY
                  ...medicines.map((med) {
                    int pricePerUnit = med.sellingPrice ?? 0; // Lấy giá bán thực tế từ Model
                    int qty = int.tryParse(med.quantity) ?? 0;
                    int itemTotal = pricePerUnit * qty;
                    String activeUnit = med.unit ?? 'Đơn vị';

                    return _buildMedicineItem(
                      med.name, 
                    'Thuốc • ${_formatMoney(pricePerUnit)}/$activeUnit', 
                      '$qty Đơn vị', 
                      _formatMoney(itemTotal)
                    );
                  }).toList(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _buildRowItem('Tổng tiền thuốc:', _formatMoney(totalMedicinesPrice), isBold: true, color: Colors.orange),
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
                      controller: _cashController,
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
                        _buildRowItem('Tổng chi phí dịch vụ:', _formatMoney(totalServicesPrice), fontSize: 13),
                        _buildRowItem('Tổng chi phí thuốc:', _formatMoney(totalMedicinesPrice), fontSize: 13),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Color(0xFFE2E8F0))),
                        _buildRowItem('TỔNG THANH TOÁN:', _formatMoney(finalTotalPrice), isBold: true, fontSize: 16, color: const Color(0xFF070412)),
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
                    onPressed: () {
                      // Xử lý in hóa đơn với dữ liệu thực tế
                    },
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
                   onPressed: () => _handlePaymentConfirm(p, totalServicesPrice, totalMedicinesPrice, finalTotalPrice)
                  ,style: ElevatedButton.styleFrom(
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

  Widget _buildMedicineItem(String title, String subTitle, String qty, String sellingPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subTitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
          Text(qty, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
          const SizedBox(width: 20),
          Text(sellingPrice, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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