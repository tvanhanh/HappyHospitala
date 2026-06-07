import 'package:flutter/material.dart';
import 'step1_page.dart';
import 'step2_page.dart';
import 'step3_page.dart';

// KHAI BÁO CÁC HẰNG SỐ MÀU DÙNG CHUNG CHO TOÀN BỘ FILE CON
const Color kPrimaryBlue = Color(0xFF3EA6E9);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kUrgentTag = Color(0xFFEA580C);
const Color kDangerRed = Color(0xFFEF4444);
const Color kSuccessGreen = Color(0xFF22C55E);

class DispenseMedicineDialog extends StatefulWidget {
  final Map<String, dynamic> prescription;

  const DispenseMedicineDialog({super.key, required this.prescription});

  @override
  State<DispenseMedicineDialog> createState() => _DispenseMedicineDialogState();
}

class _DispenseMedicineDialogState extends State<DispenseMedicineDialog> {
  int _currentStep = 0; // Trạng thái bước hiện tại

  // Mock dữ liệu gốc truyền đi cho các Page con
  final List _medicinesData = [
    {
      'name': 'Paracetamol 500mg',
      'usage': '1 viên x 3 lần/ngày',
      'qty': '30',
      'stock': 450,
      'batch': 'PC2024001',
      'exp': '2026-12-31'
    },
    {
      'name': 'Vitamin C 1000mg',
      'usage': '1 viên x 1 lần/ngày',
      'qty': '10',
      'stock': 0,
      'batch': 'TP2024003',
      'exp': '2027-03-20'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final bool isUrgent = widget.prescription['isUrgent'] ?? false;
    final double dialogHeight = MediaQuery.of(context).size.height * 0.88;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 960,
        height: dialogHeight,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                        child: const Icon(Icons.local_hospital_rounded, color: kPrimaryBlue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cấp phát thuốc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                          const SizedBox(height: 4),
                          Text('Đơn thuốc: ${widget.prescription['code']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: kUrgentTag, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Khẩn', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                ],
              ),
            ),
            const Divider(color: kBorderColor, height: 1),

            // ================= STEPPER PROGRESS INDICATOR =================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(0, 'Kiểm tra đơn'),
                  _buildStepLine(0),
                  _buildStepIndicator(1, 'Kiểm tra tương tác'),
                  _buildStepLine(1),
                  _buildStepIndicator(2, 'Xác nhận cấp phát'),
                ],
              ),
            ),

            // ================= CUỘN TRANG CHUYỂN ĐỔI BODY (Đã dọn dẹp cực sạch) =================
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentPageContent(),
              ),
            ),
            const Divider(color: kBorderColor, height: 1),

            // ================= FOOTER BUTTONS CONTROL =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _currentStep > 0 ? 'Quay lại' : 'Hủy',
                      style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        // Logic bấm nút xác nhận cuối cùng tại đây
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 2 ? kSuccessGreen : kPrimaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentStep == 2) ...[
                          const Icon(Icons.check, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _currentStep == 2 ? 'Xác nhận cấp phát' : 'Tiếp tục',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Hàm điều phối hiển thị Widget tương ứng với số bước
  Widget _buildCurrentPageContent() {
    switch (_currentStep) {
      case 0:
        return Step1Page(prescription: widget.prescription, medicines: _medicinesData);
      case 1:
        return Step2Page(medicines: _medicinesData);
      case 2:
        return Step3Page(patientName: widget.prescription['patient'] ?? 'Nguyễn Văn An');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: isActive || isCompleted ? kPrimaryBlue : const Color(0xFF94A3B8), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${stepIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? kTextDark : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    return Container(width: 60, height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 12), color: _currentStep > stepIndex ? kPrimaryBlue : kBorderColor);
  }
}