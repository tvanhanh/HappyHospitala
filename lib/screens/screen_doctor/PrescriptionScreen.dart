import 'package:flutter/material.dart';
import '../../models/medicine_model.dart'; 
import '../../models/prescription_model.dart'; 
import '../../models/clinic_service.dart';
import '../../services/api_medicine.dart';  
import '../../services/api_prescription.dart';
import '../../services/api_clinic_service.dart';

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
  final TextEditingController _medicineSearchController = TextEditingController();
  final TextEditingController _serviceSearchController = TextEditingController();

  List<MedicineModel> _allMedicines = [];      // Toàn bộ thuốc tải về từ server
  List<MedicineModel> _filteredMedicines = []; // Thuốc sau khi được tìm kiếm/lọc
  int _currentPage = 1;                         // Trang hiện tại
  final int _itemsPerPage = 10;                // Số thuốc trên mỗi trang

  List<ClinicService> _allServices = [];        // Toàn bộ dịch vụ tải về từ server
  List<ClinicService> _filteredServices = [];   // Dịch vụ sau khi lọc
  int _currentServicePage = 1;                  // Trang dịch vụ hiện tại
  final int _servicesPerPage = 10;              // Số dịch vụ mỗi trang

  bool _isSearchingMedicine = false;              
  bool _isSearchingService = false;              
  bool _isSaving = false;              
  MedicineModel? _selectedMedicine; // Lưu trực tiếp Object thuốc được chọn

  final List<Map<String, dynamic>> _prescribedMedicines = []; 
  final List<Map<String, dynamic>> _prescribedServices = []; 

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController(
        text: widget.diagnosis.isNotEmpty ? widget.diagnosis : "Chưa có chẩn đoán"
    );
    _fetchMedicines(); // Tải danh sách thuốc lần đầu
    _fetchServices();  // Tải danh sách dịch vụ lần đầu
  }

  Future<void> _fetchMedicines() async {
    setState(() => _isSearchingMedicine = true);
    try {
      final data = await ApiMedicine.getAllMedicines();
      setState(() {
        _allMedicines = data;
        _filteredMedicines = data;
        _currentPage = 1;
      });
    } catch (e) {
      print("Lỗi tải danh sách thuốc: $e");
    } finally {
      setState(() => _isSearchingMedicine = false);
    }
  }

  Future<void> _fetchServices() async {
    setState(() => _isSearchingService = true);
    try {
      final rawData = await ApiClinicService.getServices();
      final data = rawData.map((e) => ClinicService.fromJson(e)).toList();
      setState(() {
        _allServices = data;
        _filteredServices = data;
        _currentServicePage = 1;
      });
    } catch (e) {
      print("Lỗi tải danh sách dịch vụ: $e");
    } finally {
      setState(() => _isSearchingService = false);
    }
  }

  void _filterMedicines(String query) {
    setState(() {
      _filteredMedicines = _allMedicines.where((med) {
        final name = med.medicineName.toLowerCase();
        final code = med.medicineCode.toLowerCase();
        final manufacturer = med.manufacturer.toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || code.contains(search) || manufacturer.contains(search);
      }).toList();
      _currentPage = 1; // Reset về trang 1
    });
  }

  void _filterServices(String query) {
    setState(() {
      _filteredServices = _allServices.where((svc) {
        final name = svc.name.toLowerCase();
        final desc = svc.description.toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || desc.contains(search);
      }).toList();
      _currentServicePage = 1; // Reset về trang 1
    });
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
    print(appointmentId.isNotEmpty ? "Appointment ID: $appointmentId" : "Không tìm thấy ID cuộc hẹn.");
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
    if (_prescribedMedicines.isEmpty && _prescribedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn thuốc/chỉ định trống! Vui lòng chọn ít nhất một thuốc hoặc dịch vụ.")),
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
        services: _prescribedServices.map((item) => PrescribedService(
          serviceId: item['id'],
          name: item['name'],
          price: item['price'] ?? 0,
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
        services: prescriptionData.services.map((s) => s.toJson()).toList(),
        doctorId: apptData["doctorId"],     
        doctorName: apptData["doctorName"],
      ).timeout(const Duration(seconds: 15)); 

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text("🎉 Đã lưu đơn thuốc & chỉ định dịch vụ thành công!")),
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
    _medicineSearchController.dispose();
    _serviceSearchController.dispose();
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
      _medicineSearchController.clear();
      _filterMedicines(''); // Hiển thị lại toàn bộ danh mục sau khi đã thêm
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

            // Bảng tìm kiếm & danh sách thuốc phân trang
            _buildMedicineTable(),
            const SizedBox(height: 24),

            // Form nhập số lượng & cách dùng cho thuốc đang chọn
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
                  const Text("Thông tin kê đơn chi tiết", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
                  const SizedBox(height: 16),
                  
                  if (_selectedMedicine == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Vui lòng bấm 'Chọn' một loại thuốc ở bảng danh sách trên để nhập liều lượng.",
                              style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Đang chọn: ${_selectedMedicine!.medicineName} (${_selectedMedicine!.unit})",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedMedicine = null),
                          child: const Text("Bỏ chọn", style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Số lượng *", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
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
                              const Text("Hướng dẫn sử dụng *", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _usageController,
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _addMedicineToPrescription,
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text(
                        "THÊM THUỐC VÀO ĐƠN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: const Color(0xFF6366F1), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("Chọn dịch vụ kỹ thuật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 16),
            _buildServiceTable(),
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
              const SizedBox(height: 24),
            ],

            // Danh sách dịch vụ đã chọn hiển thị phía dưới
            if (_prescribedServices.isNotEmpty) ...[
              const Text("Danh sách dịch vụ đã chọn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Tên dịch vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _prescribedServices.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['name'])),
                      DataCell(Text("${(item['price'] as int).toStringAsFixed(0)} đ")),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _prescribedServices.remove(item);
                            });
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_prescribedMedicines.isNotEmpty || _prescribedServices.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePrescription, 
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? "ĐANG LƯU ĐƠN THUỐC..." : "LƯU ĐƠN THUỐC & CHỈ ĐỊNH DỊCH VỤ",
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

  Widget _buildServiceTable() {
    int totalPages = (_filteredServices.length / _servicesPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentServicePage > totalPages) {
      _currentServicePage = totalPages;
    }
    
    int startIndex = (_currentServicePage - 1) * _servicesPerPage;
    int endIndex = startIndex + _servicesPerPage;
    if (endIndex > _filteredServices.length) {
      endIndex = _filteredServices.length;
    }
    List<ClinicService> pageItems = _filteredServices.isEmpty 
        ? [] 
        : _filteredServices.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh tìm kiếm dịch vụ
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _serviceSearchController,
                onChanged: _filterServices,
                style: const TextStyle(fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm dịch vụ theo tên hoặc mô tả...",
                  prefixIcon: const Icon(Icons.search, color: Colors.black45),
                  suffixIcon: _serviceSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black45),
                          onPressed: () {
                            _serviceSearchController.clear();
                            _filterServices('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimaryBlue),
                  ),
                  fillColor: kBgColor,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryBlue),
              onPressed: _fetchServices,
              tooltip: "Tải lại danh sách",
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Danh sách dịch vụ hiển thị dạng bảng
        if (_isSearchingService)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(color: kPrimaryBlue),
            ),
          )
        else if (_filteredServices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: const Center(
              child: Text(
                "Không tìm thấy dịch vụ nào phù hợp.",
                style: TextStyle(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: kBorderColor),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Tên dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Thời lượng', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                ],
                rows: pageItems.map((svc) {
                  final isPrescribed = _prescribedServices.any((item) => item['id'] == svc.id);
                  return DataRow(
                    selected: isPrescribed,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (isPrescribed) return const Color(0xFFEFF6FF); // Light blue highlight
                      return null;
                    }),
                    cells: [
                      DataCell(Text(svc.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(svc.description, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(svc.duration)),
                      DataCell(Text("${svc.price.toStringAsFixed(0)} đ")),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (isPrescribed) {
                                _prescribedServices.removeWhere((item) => item['id'] == svc.id);
                              } else {
                                _prescribedServices.add({
                                  "id": svc.id,
                                  "name": svc.name,
                                  "price": svc.price.toInt(),
                                });
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPrescribed ? Colors.redAccent : const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: Text(
                            isPrescribed ? "Hủy chọn" : "Chọn",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phân trang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hiển thị ${startIndex + 1} - $endIndex trong tổng số ${_filteredServices.length} dịch vụ",
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentServicePage > 1
                        ? () => setState(() => _currentServicePage--)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Trang $_currentServicePage / $totalPages",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentServicePage < totalPages
                        ? () => setState(() => _currentServicePage++)
                        : null,
                  ),
                ],
              )
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMedicineTable() {
    int totalPages = (_filteredMedicines.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredMedicines.length) {
      endIndex = _filteredMedicines.length;
    }
    List<MedicineModel> pageItems = _filteredMedicines.isEmpty 
        ? [] 
        : _filteredMedicines.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh tìm kiếm thuốc
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _medicineSearchController,
                onChanged: _filterMedicines,
                style: const TextStyle(fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm thuốc theo tên, mã hoặc nhà sản xuất...",
                  prefixIcon: const Icon(Icons.search, color: Colors.black45),
                  suffixIcon: _medicineSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black45),
                          onPressed: () {
                            _medicineSearchController.clear();
                            _filterMedicines('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimaryBlue),
                  ),
                  fillColor: kBgColor,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryBlue),
              onPressed: _fetchMedicines,
              tooltip: "Tải lại danh sách",
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Danh sách hiển thị dạng bảng
        if (_isSearchingMedicine)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(color: kPrimaryBlue),
            ),
          )
        else if (_filteredMedicines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: const Center(
              child: Text(
                "Không tìm thấy loại thuốc nào phù hợp.",
                style: TextStyle(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: kBorderColor),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Mã thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Tên thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Đơn vị', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Nhà sản xuất', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                  DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark))),
                ],
                rows: pageItems.map((med) {
                  final isSelected = _selectedMedicine?.id == med.id;
                  return DataRow(
                    selected: isSelected,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (isSelected) return const Color(0xFFEEF2FF); // Light indigo highlight
                      return null;
                    }),
                    cells: [
                      DataCell(Text(med.medicineCode, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(med.medicineName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(med.unit)),
                      DataCell(Text(med.manufacturer)),
                      DataCell(Text("${med.sellingPrice.toStringAsFixed(0)} đ")),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedMedicine = med;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: Text(
                            isSelected ? "Đang chọn" : "Chọn",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phân trang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hiển thị ${startIndex + 1} - $endIndex trong tổng số ${_filteredMedicines.length} thuốc",
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Trang $_currentPage / $totalPages",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              )
            ],
          ),
        ],
      ],
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