import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final dynamic
      prescriptionData; // Nhận map dữ liệu hoặc Model từ trang danh sách truyền qua

  const PrescriptionDetailPage({super.key, required this.prescriptionData});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Map an toàn các trường dữ liệu từ JSON/Object của bạn
    final String invoiceId =
        prescriptionData['_id'] ?? prescriptionData['id'] ?? 'N/A';
    final String patientName = prescriptionData['patientName'] ?? 'Không rõ';
    final String patientId = prescriptionData['patientId'] ?? 'N/A';
    final String timeArrived = prescriptionData['timeArrived'] ?? 'N/A';
    final String paymentMethod =
        prescriptionData['paymentMethod'] ?? 'Chưa xác định';
    final double cashGiven = (prescriptionData['cashGiven'] ?? 0).toDouble();
    final double totalMedicinesPrice =
        (prescriptionData['totalMedicinesPrice'] ?? 0).toDouble();
    final double totalServicesPrice =
        (prescriptionData['totalServicesPrice'] ?? 0).toDouble();
    final double finalTotalPrice =
        (prescriptionData['finalTotalPrice'] ?? 0).toDouble();
    final List medicines = prescriptionData['medicines'] ?? [];
    final List services = prescriptionData['services'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3EA6E9),
        elevation: 0,
        title: Text(
            'Chi tiết hóa đơn #...${invoiceId.substring(invoiceId.length > 6 ? invoiceId.length - 6 : 0)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: SizedBox(
            width:
                1000, // Khóa chiều rộng tối đa để hiển thị đẹp trên màn hình Web/Tablet
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh điều hướng quay lại nhanh
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Quay lại danh sách',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // ROW CHÍNH: Chia 2 cột (Trái: Thông tin chi tiết & Danh mục, Phải: Tóm tắt thanh toán)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CỘT TRÁI (Chiếm phần lớn diện tích)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Khối thông tin chung khách hàng
                          _buildSectionCard(
                            title: 'Thông tin hành chính bệnh án',
                            icon: Icons.assignment_ind_outlined,
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildInfoItem(
                                        'Tên bệnh nhân', patientName,
                                        isHighlight: true)),
                                Expanded(
                                    child: _buildInfoItem(
                                        'Mã bệnh nhân', patientId)),
                                Expanded(
                                    child: _buildInfoItem(
                                        'Thời gian lập', timeArrived)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. Khối danh sách thuốc
                          _buildSectionCard(
                            title: 'Danh mục thuốc kê đơn',
                            icon: Icons.medication_outlined,
                            child: _buildMedicineTable(
                                medicines, currencyFormatter),
                          ),
                          const SizedBox(height: 24),

                          // 3. Khối danh sách dịch vụ lâm sàng (Nếu có)
                          _buildSectionCard(
                            title: 'Dịch vụ chỉ định đi kèm',
                            icon: Icons.medical_services_outlined,
                            child:
                                _buildServiceTable(services, currencyFormatter),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // CỘT PHẢI (Hóa đơn - Tổng tiền cố định)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biên lai thanh toán',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                            const Divider(height: 32, color: Color(0xFFE2E8F0)),
                            _buildAmountRow('Tổng tiền thuốc:',
                                currencyFormatter.format(totalMedicinesPrice)),
                            const SizedBox(height: 12),
                            _buildAmountRow('Tổng phí dịch vụ:',
                                currencyFormatter.format(totalServicesPrice)),
                            const Divider(height: 32, color: Color(0xFFE2E8F0)),
                            _buildAmountRow(
                              'Tổng cộng cần thu:',
                              currencyFormatter.format(finalTotalPrice),
                              isTotal: true,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildAmountRow('Phương thức:', paymentMethod,
                                      valueColor: Colors.black),
                                  const SizedBox(height: 8),
                                  _buildAmountRow('Khách đưa:',
                                      currencyFormatter.format(cashGiven)),
                                  const SizedBox(height: 8),
                                  _buildAmountRow(
                                      'Tiền thừa:',
                                      currencyFormatter
                                          .format(cashGiven - finalTotalPrice),
                                      valueColor: Colors.green),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Xử lý logic In hóa đơn nếu cần
                                },
                                icon:
                                    const Icon(Icons.print_outlined, size: 18),
                                label: const Text('In hóa đơn (PharmaCare)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3EA6E9),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget dùng chung để bọc các khối thông tin
  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3EA6E9), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color:
                isHighlight ? const Color(0xFF3EA6E9) : const Color(0xFF0F172A),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Bảng danh mục Thuốc mẫu
  Widget _buildMedicineTable(List medicines, NumberFormat formatter) {
    if (medicines.isEmpty) {
      return const Text('Không có dữ liệu cấp phát thuốc.',
          style: TextStyle(color: Color(0xFF64748B)));
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3), // Tên thuốc
        1: FlexColumnWidth(1), // Số lượng
        2: FlexColumnWidth(1), // ĐVT
        3: FlexColumnWidth(1.5), // Đơn giá
        4: FlexColumnWidth(1.5), // Thành tiền
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
          children: ['Tên thuốc/Vật tư', 'SL', 'ĐVT', 'Đơn giá', 'Thành tiền']
              .map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(h,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            fontSize: 13)),
                  ))
              .toList(),
        ),
        ...medicines.map((med) {
          double price = (med['sellingPrice'] ?? 0).toDouble();
          double qty = double.tryParse(med['quantity']?.toString() ?? '1') ?? 1;
          return TableRow(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(med['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)))),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(med['quantity']?.toString() ?? '0')),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(med['unit'] ?? '-')),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(formatter.format(price))),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(formatter.format(price * qty),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          );
        }),
      ],
    );
  }

  // Bảng danh mục Dịch vụ mẫu
  Widget _buildServiceTable(List services, NumberFormat formatter) {
    if (services.isEmpty) {
      return const Text('Không có dịch vụ xét nghiệm/chẩn đoán đi kèm.',
          style:
              TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic));
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
          children: ['Tên dịch vụ kĩ thuật', 'Chi phí']
              .map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(h,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            fontSize: 13)),
                  ))
              .toList(),
        ),
        ...services.map((ser) {
          // THÊM DÒNG NÀY ĐỂ DEBUG:
          print('Dữ liệu 1 dịch vụ: $ser');

          // Dùng cách ép kiểu an toàn này:
          double price =
              double.tryParse(ser['sellingPrice']?.toString() ?? '0') ?? 0.0;
          return TableRow(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(ser['name'] ?? 'N/A',
                      style: const TextStyle(color: Color(0xFF0F172A)))),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(formatter.format(price),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAmountRow(String label, String val,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ??
                (isTotal ? const Color(0xFFEF4444) : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
