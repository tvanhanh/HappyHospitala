import 'package:flutter/material.dart';
import 'step1_page.dart';
import 'step2_page.dart';
import 'step3_page.dart';
// 🟢 Bổ sung import model để sử dụng kiểu dữ liệu nghiêm ngặt
import '../../models/prescription_model.dart'; 
import '../../services/api_prescription.dart';

// CÁC HẰNG SỐ MÀU DÙNG CHUNG
const Color kPrimaryBlue = Color(0xFF3EA6E9);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kUrgentTag = Color(0xFFEA580C);
const Color kDangerRed = Color(0xFFEF4444);
const Color kSuccessGreen = Color(0xFF22C55E);

class DispenseMedicineDialog extends StatefulWidget {
  final PrescriptionModel prescription;
  final String dateDisplay;

  const DispenseMedicineDialog({super.key, required this.prescription, required this.dateDisplay,});

  @override
  State<DispenseMedicineDialog> createState() => _DispenseMedicineDialogState();
}

class _DispenseMedicineDialogState extends State<DispenseMedicineDialog> {
  int _currentStep = 0; 
  bool _isInNhanThuoc = true;    
  bool _isLuuBlockchain = true;   
  bool _isLoading = false;

  Future<void> _submitDispenseData() async {
    setState(() => _isLoading = true);
    
    // Gọi sang file Service của bạn
    bool isSuccess = await ApiPrescription.updatePrescriptionStatus(
      widget.prescription.id!,
      'completed',          
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (isSuccess) {
      Navigator.of(context).pop(true); // Đóng Dialog và báo thành công về màn hình chính
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Cấp phát thuốc thành công và đã cập nhật hệ thống!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Cập nhật thất bại. Vui lòng thử lại!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final bool isUrgent = widget.prescription.status == 'urgent';
    final double dialogHeight = MediaQuery.of(context).size.height * 0.88;
    String rawId = widget.prescription.id ?? '---';
    String shortCode = rawId.length > 5 ? rawId.substring(rawId.length - 5) : rawId;

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
                          Text('Đơn thuốc: ..$shortCode', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
                          const SizedBox(width: 4),
                          Text('Khần', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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

            // ================= CUỘN TRANG CHUYỂN ĐỔI BODY =================
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
                  // NÚT QUAY LẠI / HỦY
                  TextButton(                   
                    onPressed: _isLoading 
                        ? null 
                        : () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                            } else {
                              Navigator.pop(context, false); 
                            }
                          },
                    child: Text(
                      _currentStep > 0 ? 'Quay lại' : 'Hủy',
                      style: TextStyle(
                        color: _isLoading ? Colors.grey : kPrimaryBlue, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
          
                 ElevatedButton(
                   
                    onPressed: _isLoading 
                        ? null 
                        : () async {
                            if (_currentStep < 2) {
                              setState(() => _currentStep++);
                            } else {
                              await _submitDispenseData();
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
                        // 🟢 ĐÃ SỬA: Nếu đang gọi API, hiển thị vòng xoay tiến trình nhỏ màu trắng
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ] else if (_currentStep == 2) ...[
                          const Icon(Icons.check, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isLoading 
                              ? 'Đang đồng bộ...' 
                              : (_currentStep == 2 ? 'Xác nhận cấp phát' : 'Tiếp tục'),
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

  Widget _buildCurrentPageContent() {
    switch (_currentStep) {
      case 0:
        return Step1Page(
          prescription: widget.prescription.toJson(), 
          medicines: widget.prescription.medicines.map((m) => m.toJson()).toList(),
          dateDisplay: widget.dateDisplay, 
        );
      case 1:
        return Step2Page(
          medicines: widget.prescription.medicines.map((m) => m.toJson()).toList(),
        );
      case 2:
        return Step3Page(
          patientName: widget.prescription.patientName,
          totalMedicines: widget.prescription.medicines.length,
          isInNhanThuoc: _isInNhanThuoc,
          isLuuBlockchain: _isLuuBlockchain,
          onInNhanThuocChanged: (val) => setState(() => _isInNhanThuoc = val),
          onLuuBlockchainChanged: (val) => setState(() => _isLuuBlockchain = val),
        );
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