import 'package:flutter/material.dart';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';
import '../../widgets/dispense_dialog/dispense_medicine_dialog.dart';
import '../../services/api_prescription.dart'; 
import '../../models/prescription_model.dart';

class PendingPrescriptionsScreen extends StatefulWidget {
  const PendingPrescriptionsScreen({super.key});

  @override
  State<PendingPrescriptionsScreen> createState() => _PendingPrescriptionsScreenState();
}

class _PendingPrescriptionsScreenState extends State<PendingPrescriptionsScreen> {
  // Hệ màu thương hiệu PharmaCare đồng bộ
  static const Color kPrimaryBlue = Color(0xFF3EA6E9); 
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kUrgentBg = Color(0xFFFEF9C3); 
  static const Color kUrgentBorder = Color(0xFFEAB308); 
  static const Color kUrgentTag = Color(0xFFEA580C); 
  List<PrescriptionModel> _realPrescriptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingPrescriptions();
  }

  Future<void> _fetchPendingPrescriptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PrescriptionModel> data = await ApiPrescription.getPendingPrescriptions();
      if (!mounted) return;
      setState(() {
        _realPrescriptions = data.where((prescription) {
          return prescription.status == 'pending' || prescription.status == 'urgent'; 
        }).toList();
        
        _isLoading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Lỗi xử lý dữ liệu: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
   
    final int totalPending = _realPrescriptions.length;
    final int totalUrgent = _realPrescriptions.where((p) => p.status == 'urgent').length;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PharmaCare System", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text("Hệ thống quản lý nhà thuốc thông minh", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22), 
            onPressed: _fetchPendingPrescriptions,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Text('DS', style: TextStyle(fontSize: 11, color: kPrimaryBlue, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Text('Nguyễn Thị B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const PharmaCaseDrawer(selectedMenu: "Đơn thuốc chờ"),
      body: _buildMainContent(totalPending, totalUrgent),
    );
  }

  Widget _buildMainContent(int totalPending, int totalUrgent) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("⚠️", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPendingPrescriptions,
              icon: const Icon(Icons.refresh),
              label: const Text("Tải lại trang"),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đơn thuốc chờ xử lý',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryBlue, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalPending đơn thuốc đang chờ • $totalUrgent đơn khẩn',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (_realPrescriptions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Text(
                  "🎉 Hoàn thành! Không còn đơn thuốc nào cần xử lý lúc này.",
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: _realPrescriptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 24, 
                mainAxisSpacing: 24,    
                mainAxisExtent: 390, 
              ),
              itemBuilder: (context, index) {
                return _buildPrescriptionDetailCard(context, _realPrescriptions[index]);
              },
            ),
        ],
      ),
    );
  }

  // ================= 🟢 ĐỒNG BỘ: Đọc dữ liệu thẻ qua Object PrescriptionModel =================
  Widget _buildPrescriptionDetailCard(BuildContext context, PrescriptionModel pres) {
    // Kiểm tra điều kiện khẩn cấp qua thuộc tính Model
    final bool isUrgent = pres.status == 'urgent';
    String dateDisplay = "---";
    if (pres.createdAt != null) {
      dateDisplay = pres.createdAt!.toIso8601String().substring(0, 10);
    }
    String rawId = pres.id ?? '---';
    String shortId = rawId.length > 5 ? rawId.substring(rawId.length - 5) : rawId;

    return Container(
      decoration: BoxDecoration(
        color: isUrgent ? kUrgentBg.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? kUrgentBorder : kBorderColor,
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Phần Đầu Thẻ (Mã ID rút gọn, Ngày, Tag Khẩn)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Mã: ..$shortId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateDisplay,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kUrgentTag, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 12),
                        SizedBox(width: 2),
                        Text('Khẩn', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
              ],
            ),
          ),
          
          const Divider(color: kBorderColor, height: 1),

          // 2. Phần Thông Tin Hành Chính Thực Tế qua thuộc tính Model tường minh
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👤 ', style: TextStyle(fontSize: 14)),
                    const Text('Bệnh nhân: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Text(
                        pres.patientName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('👨‍⚕️ ', style: TextStyle(fontSize: 14)),
                    const Text('Bác sĩ kê đơn: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Text(
                        pres.doctorName, 
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Khung hiển thị danh sách thuốc lặp qua List<PrescribedMedicine> con
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor.withOpacity(0.5)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💊', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'Danh sách thuốc (${pres.medicines.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pres.medicines.map((med) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 2),
                                  Text(med.usage, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                'SL: ${med.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 4. Nút bấm mở Dialog xác nhận cấp thuốc
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
    
                      final bool? isDispensSucceed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                        return DispenseMedicineDialog(prescription: pres, dateDisplay: dateDisplay,);
                          
                        },
                      );

                      if (isDispensSucceed == true) {
                        _fetchPendingPrescriptions();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUrgent ? kUrgentTag : kPrimaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'CẤP PHÁT THUỐC',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}