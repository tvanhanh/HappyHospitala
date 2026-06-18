import 'package:flutter/material.dart';
import '../../models/medicine_model.dart'; 
import '../../models/prescription_model.dart'; 
import '../../services/api_medicine.dart';  
import '../../services/api_prescription.dart';

class PrescriptionScreen extends StatefulWidget {
  final dynamic appointment; 
  final String diagnosis;     

  const PrescriptionScreen({
    Key? key,
    required this.appointment,
    required this.diagnosis,
  }) : super(key: key);

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  static const Color kPrimaryBlue = Color(0xFF1565C0);
  static const Color kBgColor = Color(0xFFF8FAFC);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextDark = Color(0xFF1E293B);

  late TextEditingController _diagnosisController;
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final TextEditingController _usageController = TextEditingController(text: "Uống sau ăn, ngày 2 lần");
  final SearchController _searchController = SearchController(); // Điều khiển ô tìm kiếm thuốc

  List<MedicineModel> _searchResults = []; // Lưu kết quả tìm kiếm thuốc tạm thời
  bool _isSearchingMedicine = false;              
  bool _isSaving = false;              
  MedicineModel? _selectedMedicine; // Lưu trực tiếp Object thuốc được chọn thay vì chỉ lưu ID

  final List<Map<String, dynamic>> _prescribedMedicines = []; 

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController(
        text: widget.diagnosis.isNotEmpty ? widget.diagnosis : "Chưa có chẩn đoán"
    );
  }

  // Hàm gọi API tìm kiếm thuốc khi bác sĩ gõ chữ
  Future<void> _searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearchingMedicine = true);
    try {
      // Giả định API của bạn hỗ trợ truyền query tìm kiếm, ví dụ: ApiMedicine.searchMedicines(query)
      // Nếu ApiMedicine chỉ có getAllMedicines(), bạn có thể lọc tạm ở client hoặc cập nhật API backend nhé!
      final data = await ApiMedicine.getAllMedicines(); 
      
      setState(() {
        // Lọc danh sách thuốc theo tên (bỏ qua hoa thường)
        _searchResults = data.where((med) => 
          med.medicineName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    } catch (e) {
      print("Lỗi tìm kiếm thuốc: $e");
    } finally {
      setState(() => _isSearchingMedicine = false);
    }
  }

  Map<String, String?> _extractAppointmentData() {
    final dynamic appt = widget.appointment;
    if (appt == null) {
      return {
        "id": "", "patientId": "---", "patientName": "Chưa chọn bệnh nhân",
        "phone": "---", "birthDate": null, "gender": "Nam", "healthInsurance": null,"doctorId": "---", "doctorName": "Chưa rõ bác sĩ"
      };
    }

    Map<String, dynamic> apptMap = {};
    try { apptMap = appt.toJson(); } catch (_) {}

    String getStringField(String key, String? Function() objectFallback) {
      if (apptMap.containsKey(key) && apptMap[key] != null) {
        return apptMap[key].toString();
      }
      try { return objectFallback() ?? ""; } catch (_) { return ""; }
    }

    final String appointmentId = getStringField('id', () => appt.id);
    final String patientId = getStringField('patientId', () => appt.patientId).isNotEmpty 
        ? getStringField('patientId', () => appt.patientId) 
        : getStringField('idBN', () => null);

    final String patientName = getStringField('patientName', () => appt.patientName);
    final String doctorId = getStringField('doctorId', () => appt.doctorId).isNotEmpty
        ? getStringField('doctorId', () => appt.doctorId)
        : getStringField('idBS', () => null);

    final String doctorName = getStringField('doctorName', () => appt.doctorName).isNotEmpty
        ? getStringField('doctorName', () => appt.doctorName)
        : getStringField('tenBS', () => null);
    
    String? phone = apptMap['patientPhone'] ?? apptMap['phone'] ?? apptMap['sdt'] ?? apptMap['telephone'];
    if (phone == null || phone.trim().isEmpty) { 
      try { phone = appt.patientPhone ?? appt.phone ?? appt.sdt; } catch (_) {} 
    }

    String? birthDate = apptMap['birthDate'] ?? apptMap['ngaySinh'];
    if (birthDate == null) { try { birthDate = appt.birthDate ?? appt.ngaySinh; } catch (_) {} }

    String? gender = apptMap['gender'] ?? apptMap['gioiTinh'];
    if (gender == null) { try { gender = appt.gender ?? appt.gioiTinh; } catch (_) {} }

    String? healthInsurance = apptMap['healthInsurance'] ?? apptMap['bhyt'];
    if (healthInsurance == null) { try { healthInsurance = appt.healthInsurance ?? appt.bhyt; } catch (_) {} }

    return {
      "id": appointmentId.isEmpty ? "---" : appointmentId,
      "patientId": patientId.isEmpty ? "---" : patientId,
      "patientName": patientName.isEmpty ? "Không rõ" : patientName,
      "phone": (phone != null && phone.trim().isNotEmpty) ? phone : "---",
      "birthDate": birthDate,
      "gender": gender ?? "Nam",
      "healthInsurance": healthInsurance,
      "doctorId": doctorId.isEmpty ? "---" : doctorId,
      "doctorName": doctorName.isEmpty ? "Chưa rõ bác sĩ" : doctorName,
    };
  }

  Future<void> _savePrescription() async {
    if (_prescribedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn thuốc trống! Vui lòng thêm ít nhất một loại thuốc.")),
      );
      return;
    }

    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền thông tin chẩn đoán bệnh!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apptData = _extractAppointmentData();

      final prescriptionData = PrescriptionModel(
        appointmentId: apptData["id"]!,
        diagnosis: _diagnosisController.text.trim(),
        status: "pending",
        patientId: apptData["patientId"]!,
        patientName: apptData["patientName"]!,
        patientPhone: apptData["phone"] != "---" ? apptData["phone"] : null,
        birthDate: apptData["birthDate"],
        gender: apptData["gender"],
        healthInsurance: apptData["healthInsurance"], 
        medicines: _prescribedMedicines.map((item) => PrescribedMedicine(
          medicineId: item['id'],
          name: item['name'],
          quantity: item['quantity'],
          usage: item['usage'],
          sellingPrice: item['sellingPrice'] ?? 0,
          unit: item['unit'] ?? '',
        )).toList(),
        doctorId: apptData["doctorId"]!,
        doctorName: apptData["doctorName"]!,
      );
    
      final success = await ApiPrescription.createPrescription(
        appointmentId: prescriptionData.appointmentId,
        diagnosis: prescriptionData.diagnosis,
        patientId: prescriptionData.patientId,
        patientName: prescriptionData.patientName,
        patientPhone: prescriptionData.patientPhone,
        birthDate: prescriptionData.birthDate,
        gender: prescriptionData.gender,
        healthInsurance: prescriptionData.healthInsurance,
        medicines: prescriptionData.medicines.map((m) => m.toJson()).toList(),
        doctorId: apptData["doctorId"],     
        doctorName: apptData["doctorName"],
      ).timeout(const Duration(seconds: 15)); 

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text("🎉 Đã lưu đơn thuốc thành công vào hệ thống!")),
          );
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.redAccent, content: Text("💥 Lưu đơn thất bại, Backend từ chối request.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("💥 Có lỗi xảy ra: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _quantityController.dispose();
    _usageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addMedicineToPrescription() {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng tìm và chọn một loại thuốc từ danh sách!")),
      );
      return;
    }

    setState(() {
      _prescribedMedicines.add({
        "id": _selectedMedicine!.id,
        "name": _selectedMedicine!.medicineName, 
        "quantity": _quantityController.text,
        "usage": _usageController.text,
        "sellingPrice": _selectedMedicine!.sellingPrice ?? 0,
        "unit": _selectedMedicine!.unit ?? '',
      });
      
      // Reset trường thông tin nhập sau khi thêm thành công
      _selectedMedicine = null;
      _searchController.clear();
      _quantityController.text = "1";
      _usageController.text = "Uống sau ăn, ngày 2 lần";
    });
  }

  @override
  Widget build(BuildContext context) {
    final apptData = _extractAppointmentData();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Kê Đơn Thuốc Hệ Thống", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xffEFF6FF),
                  child: Icon(Icons.assignment_ind_rounded, color: Colors.blue.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kê đơn thuốc mới", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTextDark)),
                    SizedBox(height: 4),
                    Text("Chọn bệnh nhân và kê đơn thuốc", style: TextStyle(fontSize: 14, color: Colors.black45)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: kBorderColor),
            const SizedBox(height: 24),

            const Text("Tìm bệnh nhân", style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: kBorderColor), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${apptData['patientId']} - ${apptData['patientName']}", style: const TextStyle(fontSize: 15, color: kTextDark)),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Patient Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Wrap(
                spacing: 40,
                runSpacing: 16,
                children: [
                  _buildPatientMetaItem("Bệnh nhân", apptData['patientName'] ?? "Không rõ", isHighlight: true),
                  _buildPatientMetaItem("Mã BN", apptData['patientId'] ?? "---"),
                  _buildPatientMetaItem("SĐT", apptData['phone'] ?? "---"), 
                  _buildPatientMetaItem("Ngày sinh", apptData['birthDate'] ?? "---"),
                  _buildPatientMetaItem("Giới tính", apptData['gender'] ?? "---"),
                  _buildPatientMetaItem("BHYT", apptData['healthInsurance'] ?? "---"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Chẩn đoán *", style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _diagnosisController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15, color: kTextDark),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryBlue)),
              ),
            ),
            const SizedBox(height: 32),

            const Text("Chọn thuốc kê đơn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 16),

            // Khu vực chọn thuốc (Đã tối ưu hóa sang Ô Tìm Kiếm)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBgColor, 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 CẢI TIẾN CHÍNH: Thay Dropdown bằng SearchAnchor tìm kiếm thông minh
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tìm và chọn thuốc", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            SearchAnchor(
                              searchController: _searchController,
                              builder: (BuildContext context, SearchController controller) {
                                return SearchBar(
                                  controller: controller,
                                  hintText: "Gõ tên thuốc để tìm...",
                                  padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16)),
                                  onTap: () {
                                    controller.openView();
                                  },
                                  onChanged: (value) {
                                    _searchMedicines(value);
                                  },
                                  leading: const Icon(Icons.search, color: Colors.black45),
                                  trailing: _isSearchingMedicine 
                                    ? [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))] 
                                    : null,
                                  elevation: const WidgetStatePropertyAll<double>(0),
                                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: const BorderSide(color: kBorderColor),
                                    ),
                                  ),
                                );
                              },
                              suggestionsBuilder: (BuildContext context, SearchController controller) {
                                // Nếu chưa gõ gì hoặc không tìm thấy kết quả
                                if (_searchResults.isEmpty) {
                                  return [
                                    const ListTile(title: Text("Không tìm thấy thuốc phù hợp hoặc chưa nhập từ khóa"))
                                  ];
                                }
                                
                                return _searchResults.map((MedicineModel med) {
                                  return ListTile(
                                    title: Text(med.medicineName),
                                    subtitle: Text("Đơn vị: ${med.unit ?? 'Chưa rõ'} - Giá: ${med.sellingPrice ?? 0}đ"),
                                    onTap: () {
                                      setState(() {
                                        _selectedMedicine = med;
                                        _searchController.text = "${med.medicineName} (${med.unit ?? ''})";
                                      });
                                      controller.closeView(med.medicineName);
                                    },
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Số lượng", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kPrimaryBlue)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hướng dẫn sử dụng", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usageController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kPrimaryBlue)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _addMedicineToPrescription,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "THÊM THUỐC VÀO ĐƠN",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      backgroundColor: const Color(0xFF6366F1), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Danh sách thuốc đã chọn hiển thị phía dưới
            if (_prescribedMedicines.isNotEmpty) ...[
              const Text("Danh sách thuốc đã chọn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Tên thuốc', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Cách dùng', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _prescribedMedicines.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['name'])),
                      DataCell(Text(item['quantity'])),
                      DataCell(Text(item['usage'])),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _prescribedMedicines.remove(item);
                            });
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40), 

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePrescription, 
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? "ĐANG LƯU ĐƠN THUỐC..." : "LƯU ĐƠN THUỐC VÀO HỆ THỐNG",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientMetaItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: kTextDark,
          ),
        ),
      ],
    );
  }
}