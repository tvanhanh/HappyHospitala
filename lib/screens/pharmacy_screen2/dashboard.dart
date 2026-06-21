import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/pharmacy/pharmaCase_drawer.dart';
import '../../services/api_prescription.dart';
import '../../services/api_inventory.dart';
import '../../services/api_medicine.dart'; 
import '../../models/prescription_model.dart'; 
import '../../models/inventory_model.dart';  
import '../../widgets/pharmacy/medicine_alert_page.dart';
import '../../widgets/pharmacy/pharma_notification_bell.dart';
import '../../widgets/pharmacy/CreateImportDialog.dart';
class PharmaCareDashboardScreen extends StatefulWidget {
  const PharmaCareDashboardScreen({super.key});

  @override
  State<PharmaCareDashboardScreen> createState() => _PharmaCareDashboardScreenState();
}

class _PharmaCareDashboardScreenState extends State<PharmaCareDashboardScreen> {
  static const Color kAppBarColor = Color(0xFF3EA6E9); 
  static const Color kTextBlue = Color(0xFF3EA6E9);    
  static const Color kBgColor = Color(0xFFF8FAFC);     
  static const Color kBorderColor = Color(0xFFE2E8F0);

  String _pharmacistName = "Đang tải...";
  String _roleName = "Dược sĩ";
  String _shortName = "DS";
  bool _isLoadingData = true;
  
  // Danh sách lưu trữ các lô hàng cần chú ý kèm theo đơn vị tính đã được map bổ sung
  List<Map<String, dynamic>> _attentionMedicinesWithUnit = []; 
  List<PrescriptionModel> _pendingPrescriptions = []; 

  int _totalMedicinesCount = 0;
  int _pendingCount = 0;
  int _attentionCount = 0;
  int _dispensedTodayCount = 0;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _loadUserData();      
    await _fetchDashboardData(); 
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('name');
      String? savedRole = prefs.getString('role');

      final userString = prefs.getString('user_data');
      if (userString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userString);
        savedName = userMap['name'];
        savedRole = userMap['role'];
      }

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _pharmacistName = savedName!;
          _roleName = (savedRole == "pharmacist" || savedRole == "Pharmacist") ? "Dược sĩ chính" : (savedRole ?? "Dược sĩ");
          
          List<String> nameParts = _pharmacistName.trim().split(" ");
          if (nameParts.isNotEmpty) {
            String lastWord = nameParts.last;
            _shortName = lastWord.substring(0, lastWord.length >= 2 ? 2 : 1).toUpperCase();
          }
        });
      } else {
        setState(() {
          _pharmacistName = "Dược sĩ hệ thống";
        });
      }
    } catch (e) {
      setState(() {
        _pharmacistName = "Dược sĩ Admin";
      });
    }
  }

 Future<void> _fetchDashboardData() async {
    setState(() => _isLoadingData = true);
    try {
      // 1. Gọi song song 3 API để tối ưu hiệu năng
      final futures = await Future.wait([
        ApiInventory.getInventories(),
        ApiMedicine.getAllMedicines(), 
        ApiPrescription.getPendingPrescriptions(),
      ]);

      List<InventoryModel> allInventories = futures[0] as List<InventoryModel>;
      dynamic rawMedicines = futures[1]; 
      List<PrescriptionModel> allPrescriptions = futures[2] as List<PrescriptionModel>;

      // 2. Chuyển danh mục thuốc gốc thành Map để tra cứu O(1) theo ID thuốc
     Map<String, dynamic> medicineMap = {};
      if (rawMedicines != null) {
        for (var med in rawMedicines) {
          final String medId = med.id ?? med.idObj ?? ''; 
          if (medId.isNotEmpty) {
            medicineMap[medId] = med;
          }
        }
      }
      // 3. Duyệt danh sách kho và áp dụng logic so sánh cảnh báo mới
      List<Map<String, dynamic>> computedAttentionList = [];
      for (var inv in allInventories) {
        final String targetMedId = inv.medicineId.toString();
        
        // Tìm thông tin thuốc gốc từ map
        dynamic originalMedicine = medicineMap[targetMedId];

        // Lấy minStock và unit từ bảng thuốc (Nếu không có thì fallback về giá trị mặc định của kho)
        int dynamicMinStock = originalMedicine != null ? (originalMedicine.minStock ?? 0) : inv.minStock;
        String dynamicUnit = originalMedicine != null ? (originalMedicine.unit ?? 'đơn vị') : 'đơn vị';

        // Cập nhật lại thuộc tính minStock của đối tượng kho để đồng bộ dữ liệu hiển thị
        inv.minStock = dynamicMinStock;

        // 🟢 LOGIC THEO YÊU CẦU: Nếu số tồn hiện tại nhỏ hơn mức sàn cộng thêm 5 (currentQuantity < minStock + 5)
        if (inv.currentQuantity < (dynamicMinStock + 5)) {
          
          // Xác định mức độ nghiêm trọng để đổi màu sắc trên giao diện (nếu muốn)
          bool isCritical = inv.currentQuantity <= dynamicMinStock; 

          computedAttentionList.add({
            'inventory': inv,
            'unit': dynamicUnit,
            'isCritical': isCritical, // true nếu lọt thỏm dưới minStock, false nếu nằm trong vùng cảnh báo sớm (+5)
          });
        }
      }

      // 4. Lọc các đơn thuốc đang chờ xử lý
      _pendingPrescriptions = allPrescriptions.where((prescription) {
        return prescription.status.toLowerCase().trim() == 'pending';
      }).toList();

      setState(() {
        _attentionMedicinesWithUnit = computedAttentionList;
        _attentionCount = _attentionMedicinesWithUnit.length;
        _pendingCount = _pendingPrescriptions.length;
        _totalMedicinesCount = allInventories.length; 
        
        _dispensedTodayCount = allPrescriptions.where((p) => 
          p.status.toLowerCase() == 'dispensed' || p.status.toLowerCase() == 'completed'
        ).length; 
        
        _isLoadingData = false;
      });
    } catch (e) {
      print("💥 Lỗi xử lý so sánh định mức cảnh báo tại Dashboard: $e");
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentHour = DateTime.now().hour;
    String greetingText = 'Chào buổi làm việc!';
    if (currentHour >= 5 && currentHour < 11) {
      greetingText = 'Chào buổi sáng, $_pharmacistName!';
    } else if (currentHour >= 11 && currentHour < 14) {
      greetingText = 'Chào buổi trưa, $_pharmacistName!';
    } else if (currentHour >= 14 && currentHour < 18) {
      greetingText = 'Chào buổi chiều, $_pharmacistName!';
    } else {
      greetingText = 'Chào buổi tối, $_pharmacistName!';
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
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
          const PharmaNotificationBell(),
          Stack(
            alignment: Alignment.center,

          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(_shortName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kAppBarColor)),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_roleName, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text(_pharmacistName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const PharmaCaseDrawer(selectedMenu: "Tổng quan"),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator(color: kAppBarColor)) 
        : RefreshIndicator(
            onRefresh: _fetchDashboardData, 
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greetingText, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kTextBlue, letterSpacing: -0.5)),
                  const SizedBox(height: 32),

                  // Cảnh báo hết hàng dựa trên dữ liệu thật
                  if (_attentionMedicinesWithUnit.any((item) => (item['inventory'] as InventoryModel).currentQuantity == 0))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildAlertBox(
                        icon: Icons.dangerous_rounded,
                        iconColor: const Color(0xFFDC2626),
                        title: '⚠️ Cảnh báo nghiêm trọng: Hết hàng trong kho',
                        content: 'Hệ thống phát hiện có một số mặt hàng đã chạm mốc 0. Vui lòng lập phiếu nhập kho bổ sung.',
                        borderColor: const Color(0xFFFCA5A5),
                        bgColor: const Color(0xFFFEF2F2),
                      ),
                    ),
                  
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildStatCard(title: 'Tổng thuốc trong kho', value: '$_totalMedicinesCount', subText: '📦 Lô hàng đang quản lý', themeColor: const Color(0xFF0EA5E9), icon: Icons.archive_outlined),
                      _buildStatCard(title: 'Đơn thuốc chờ', value: '$_pendingCount', subText: '🕒 Đơn trạng thái Chờ xử lý', themeColor: const Color(0xFFD97706), icon: Icons.assignment_outlined),
                      _buildStatCard(title: 'Thuốc cần chú ý', value: '$_attentionCount', subText: '⚠ Đang ở dưới mức tối thiểu', themeColor: const Color(0xFFEF4444), icon: Icons.report_problem_outlined),
                      _buildStatCard(title: 'Đã cấp hôm nay', value: '$_dispensedTodayCount', subText: '✓ Hoàn thành trong ngày', themeColor: const Color(0xFF10B981), icon: Icons.check_circle_outline),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CỘT 1: THUỐC CẦN CHÚ Ý
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Text('💊', style: TextStyle(fontSize: 18)),
                                      SizedBox(width: 8),
                                      Text('Thuốc cần chú ý (Dưới định mức)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                  TextButton(onPressed: () {
                                    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicineAlertPage()),
        ).then((_) => _fetchDashboardData());
      
                                  }, child: const Text('Xem tất cả', style: TextStyle(color: kAppBarColor, fontWeight: FontWeight.bold)))
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              if (_attentionMedicinesWithUnit.isEmpty)
                                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Kho hàng an toàn. Toàn bộ thuốc đều nằm trên mức sàn.", style: TextStyle(color: Colors.grey)))
                              else
                                ..._attentionMedicinesWithUnit.map((item) {
                                  final InventoryModel medicine = item['inventory'] as InventoryModel;
                                  final String unit = item['unit'] as String; // Đơn vị tính động: Hộp, Viên, Chai...
                                  final bool isCritical = item['isCritical'] as bool;
                                  final int stock = medicine.currentQuantity;
                                  final String lot = medicine.batchNumber.isNotEmpty ? medicine.batchNumber : 'N/A';
                                  
                                  String subInfo = "";
                                  if (stock == 0) {
                                    subInfo = "🔴 Đã hết sạch hàng (Mức sàn cấu hình: ${medicine.minStock} $unit)";
                                  } else if (isCritical) {
                                  subInfo = "❌ Nguy hiểm: Tồn kho hiện tại ($stock $unit) đã dưới mức sàn tối thiểu (${medicine.minStock} $unit)";}
                                  else {
                                    subInfo = "⚠ Tồn hiện tại: $stock $unit  •  Mức sàn: ${medicine.minStock} $unit  •  Lô: $lot";
                                  }
                                  
                                  if (medicine.expiryDate != null) {
                                    subInfo += "  •  HSD: ${medicine.expiryDate!.toString().substring(0, 10)}";
                                  }

                                  return _buildAttentionMedicineItem(
                                    name: medicine.medicineName,
                                    subInfo: subInfo,
                                    isCritical: stock == 0,
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // CỘT 2: ĐƠN THUỐC MỚI NHẤT
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('📋', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  const Text('Đơn thuốc mới nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(12)),
                                    child: Text('$_pendingCount chờ', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              if (_pendingPrescriptions.isEmpty)
                                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Không còn đơn thuốc nào đang chờ xử lý.", style: TextStyle(color: Colors.grey)))
                              else
                                ..._pendingPrescriptions.map((prescription) {
                                  final String code = prescription.id ?? 'Chưa cấp mã';
                                  final String patientName = prescription.patientName;
                                  final String doctorName = prescription.doctorName;
                                  final int medicinesCount = prescription.medicines.length;

                                  return _buildPrescriptionItem(
                                    code: code.length > 8 ? "Mã: ...${code.substring(code.length - 6)}" : code,
                                    patientName: patientName,
                                    doctor: "$doctorName • $medicinesCount loại thuốc",
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAttentionMedicineItem({required String name, required String subInfo, required bool isCritical}) {
    final cardBgColor = isCritical ? const Color(0xFFFDF2F2) : const Color(0xFFFFFBEB);
    final iconData = isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
    final iconColor = isCritical ? const Color(0xFFEF4444) : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(iconData, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(subInfo, style: TextStyle(color: iconColor.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
         InkWell(
  onTap: () {
    // 🟢 Điều hướng sang trang nhập kho thực tế của bạn
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateImportDialog(), 
      ),
    );
  },
  borderRadius: BorderRadius.circular(8), // Tạo hiệu ứng bo góc khi click (nếu có background)
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Tạo vùng đệm bấm dễ hơn
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_box_outlined, color: Color(0xFF475569), size: 16), // Thêm icon trực quan (nếu thích)
        const SizedBox(width: 6),
        const Text(
          'NHẬP HÀNG', 
          style: TextStyle(
            color: Color(0xFF475569), 
            fontWeight: FontWeight.bold, 
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
)
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem({required String code, required String patientName, required String doctor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('BN: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              Expanded(child: Text(patientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)))),
            ],
          ),
          const SizedBox(height: 6),
          Text(doctor, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAlertBox({required IconData icon, required Color iconColor, required String title, required String content, required Color borderColor, required Color bgColor}) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: 1.5)), child: Row(children: [Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))), const SizedBox(height: 4), Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500))]))]));
  }

  Widget _buildStatCard({required String title, required String value, required String subText, required Color themeColor, required IconData icon}) {
    return Container(width: 260, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500))), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20))]), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(subText, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500))]));
  }
}