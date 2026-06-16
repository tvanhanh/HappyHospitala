import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter_application_datlichkham/services/api_medicalRecord.dart';

import '../../models/appointment.dart';
import '../../services/api_aiService.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import '../../services/api_appointment.dart';
import 'PrescriptionScreen.dart';

class EmrAiFormWidget extends StatefulWidget {
  final Appointment appointment;
  final int Function(String) calculateAge;
  final String Function(String) formatDateToDdMmYyyy;
  final VoidCallback onSuccess;

  const EmrAiFormWidget({
    super.key,
    required this.appointment,
    required this.calculateAge,
    required this.formatDateToDdMmYyyy,
    required this.onSuccess,
  });

  @override
  State<EmrAiFormWidget> createState() => _EmrAiFormWidgetState();
}

class _EmrAiFormWidgetState extends State<EmrAiFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _ureaController = TextEditingController();
  final _creatinineController = TextEditingController();
  final _hba1cController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  final _hdlController = TextEditingController();
  final _ldlController = TextEditingController();
  final _vldlController = TextEditingController();
  final _bmiController = TextEditingController();

  final _statusController = TextEditingController(text: "Không mắc bệnh");
  final _treatmentController = TextEditingController(
      text: "Điều chỉnh chế độ dinh dưỡng, giảm tinh bột và chất béo. Tập thể dục định kỳ và theo dõi sức khỏe.");
  bool _isSubmitting = false;
  bool _isAIPredicting = false;

  // CSV test data auto-fill
  List<List<dynamic>> _csvDataset = [];
  int _csvCurrentIndex = 0;
  String? _aiDiagnosisResult;
  String _aiSuggestedStatus = "Không mắc bệnh";

  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    try {
      final rawData = await rootBundle.loadString("assets/diabetes_test.csv");
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      if (listData.isNotEmpty) listData.removeAt(0);
      setState(() {
        _csvDataset = listData;
        _csvCurrentIndex = 0;
      });
    } catch (e) {
      debugPrint("Lỗi tải CSV: $e");
    }
  }

  /// 🍏 HÀM ĐIỀU HƯỚNG CHUYỂN TRANG RIÊNG LẺ (Dùng chung cho cả 2 luồng)
  void _navigateToPrescriptionScreen() {
    // Đóng Bottom Sheet Form EMR hiện tại
    Navigator.pop(context); 
    
    // Điều hướng sang màn hình kê đơn và truyền dữ liệu
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionScreen(
          appointment: widget.appointment, // Truyền object thông tin lịch hẹn bệnh nhân
          diagnosis: _statusController.text.trim(), // Truyền kèm kết quả chẩn đoán hiện tại
        ),
      ),
    );
  }

  /// 🟢 HÀM LUỒNG CŨ: LƯU BỆNH ÁN THÀNH CÔNG -> HIỂN THỊ HỘP THOẠI HỎI KÊ ĐƠN
  Future<void> _handleSaveAndPrescribe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final response = await MedicalRecordService.addMedicalRecord(
        patientId: widget.appointment.patientId,
        doctorId: widget.appointment.doctorId,
        patientName: widget.appointment.patientName,
        email: widget.appointment.patientEmail,
        examinationDate: widget.formatDateToDdMmYyyy(widget.appointment.date),
        examinationTime: widget.appointment.time,
        doctorName: widget.appointment.doctorName,
        departmentName: widget.appointment.departmentName.isNotEmpty
            ? widget.appointment.departmentName
            : widget.appointment.doctorSpecialty,
        gender: widget.appointment.gender.isNotEmpty ? widget.appointment.gender : "Nam",
        age: widget.calculateAge(widget.appointment.birthDate) > 0
            ? widget.calculateAge(widget.appointment.birthDate)
            : 30,
        urea: double.tryParse(_ureaController.text),
        creatinine: double.tryParse(_creatinineController.text),
        hba1c: double.tryParse(_hba1cController.text),
        cholesterol: double.tryParse(_cholesterolController.text),
        triglycerides: double.tryParse(_triglyceridesController.text),
        hdl: double.tryParse(_hdlController.text),
        ldl: double.tryParse(_ldlController.text),
        vldl: double.tryParse(_vldlController.text),
        bmi: double.tryParse(_bmiController.text),
        status: _statusController.text.trim(),
        symptoms: widget.appointment.reason.isNotEmpty ? widget.appointment.reason : "Không ghi nhận",
        treatment: _treatmentController.text.trim(),
      );

      if (!mounted) return;

      if (response == "success") {
        await AppointmentApi.updateStatus(id: widget.appointment.id, status: 'completed');
        if (!mounted) return;
        widget.onSuccess();

        final bool? confirmPrescription = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: const [
                  Icon(Icons.medical_services_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Kê đơn thuốc", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                "Bệnh án EMR đã được lưu thành công!\nBạn có muốn tiến hành kê đơn thuốc cho bệnh nhân này luôn không?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Không", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Có", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        if (confirmPrescription == true) {
          _navigateToPrescriptionScreen();
        } else {
          Navigator.pop(context); 
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi lưu dữ liệu: $response"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi hệ thống xảy ra: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _fillNextFromCSV() {
    if (_csvDataset.isEmpty) return;
    setState(() {
      final row = _csvDataset[_csvCurrentIndex];
      _csvCurrentIndex = (_csvCurrentIndex + 1) % _csvDataset.length;
      _ureaController.text = row[2].toString();
      _creatinineController.text = row[3].toString();
      _hba1cController.text = row[4].toString();
      _cholesterolController.text = row[5].toString();
      _triglyceridesController.text = row[6].toString();
      _hdlController.text = row[7].toString();
      _ldlController.text = row[8].toString();
      _vldlController.text = row[9].toString();
      _bmiController.text = row[10].toString();
    });
  }

  String _formatResult(dynamic data) {
    if (data == null) return "";
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _formatResult(decoded);
      } catch (_) {
        return data.replaceAll(RegExp(r'[{}]'), '').trim();
      }
    }
    if (data is Map) {
      return data.entries.map((e) {
        if (e.key.toString().toLowerCase().contains("xác suất")) {
          return "${e.key}:\n${e.value}";
        }
        return "${e.key}: ${e.value}";
      }).join("\n\n");
    }
    if (data is List) {
      return data.map((e) => _formatResult(e)).join("\n");
    }
    return data.toString();
  }

  Future<void> _runAIPrediction() async {
    if (_ureaController.text.isEmpty || _bmiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ chỉ số!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAIPredicting = true);

    final double? urea = double.tryParse(_ureaController.text);
    final double? creatinine = double.tryParse(_creatinineController.text);
    final double? hba1c = double.tryParse(_hba1cController.text);
    final double? cholesterol = double.tryParse(_cholesterolController.text);
    final double? triglycerides = double.tryParse(_triglyceridesController.text);
    final double? hdl = double.tryParse(_hdlController.text);
    final double? ldl = double.tryParse(_ldlController.text);
    final double? vldl = double.tryParse(_vldlController.text);
    final double? bmi = double.tryParse(_bmiController.text);

    final int age = widget.calculateAge(widget.appointment.birthDate);
    final String safeGender = widget.appointment.gender.toLowerCase().contains("nam") ? "M" : "F";

    final patientData = {
      "Gender": safeGender,
      "AGE": age > 0 ? age : 30,
      "Urea": urea ?? 0.0,
      "Cr": creatinine ?? 0.0,
      "HbA1c": hba1c ?? 0.0,
      "Chol": cholesterol ?? 0.0,
      "TG": triglycerides ?? 0.0,
      "HDL": hdl ?? 0.0,
      "LDL": ldl ?? 0.0,
      "VLDL": vldl ?? 0.0,
      "BMI": bmi ?? 0.0,
    };

    try {
      final response = await AIService.predictDisease(patientData);
      if (!mounted) return;
      String pred = response.toString();
      String exactPred = pred;
      final match = RegExp(r'Dự\s*đoán\s*[:=]\s*([^,}]+)', caseSensitive: false).firstMatch(pred);
      if (match != null) {
        exactPred = match.group(1)!.trim();
      } else {
        exactPred = pred.replaceAll(RegExp(r'[{}]'), '').trim();
      }

      if (exactPred.contains("Mắc bệnh") && !exactPred.contains("Không")) {
        exactPred = "Mắc bệnh tiểu đường";
      } else if (exactPred.contains("Không mắc bệnh")) {
        exactPred = "Không mắc bệnh tiểu đường";
      }

      setState(() {
        _aiDiagnosisResult = response;
        _aiSuggestedStatus = exactPred;
        _statusController.text = exactPred;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi chạy AI: $e")));
    } finally {
      if (mounted) setState(() => _isAIPredicting = false);
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    _ureaController.dispose();
    _creatinineController.dispose();
    _hba1cController.dispose();
    _cholesterolController.dispose();
    _triglyceridesController.dispose();
    _hdlController.dispose();
    _ldlController.dispose();
    _vldlController.dispose();
    _bmiController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5, width: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Hồ Sơ Bệnh Án EMR",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _fillNextFromCSV,
                        icon: const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFF3B82F6)),
                        label: Text(
                            _csvDataset.isEmpty
                                ? "Tải dữ liệu mẫu"
                                : "Auto-fill (${_csvCurrentIndex + 1}/${_csvDataset.length})",
                            style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Chỉ số Hóa sinh máu",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _modernField(_ureaController, "Urea", "mmol/L")),
                            const SizedBox(width: 12),
                            Expanded(child: _modernField(_creatinineController, "Cr", "µmol/L"))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _modernField(_hba1cController, "HbA1c", "%")),
                            const SizedBox(width: 12),
                            Expanded(child: _modernField(_cholesterolController, "Chol", "mmol/L"))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _modernField(_triglyceridesController, "TG", "mmol/L")),
                            const SizedBox(width: 12),
                            Expanded(child: _modernField(_hdlController, "HDL", "mmol/L"))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _modernField(_ldlController, "LDL", "mmol/L")),
                            const SizedBox(width: 12),
                            Expanded(child: _modernField(_vldlController, "VLDL", "mmol/L"))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _modernField(_bmiController, "BMI", "kg/m²")),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox.shrink())
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isAIPredicting ? null : _runAIPrediction,
                        icon: _isAIPredicting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.psychology, color: Colors.white),
                        label: Text(_isAIPredicting ? "AI đang phân tích..." : "Phân tích bằng AI", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5)),
                      ),
                    ),
                    if (_aiDiagnosisResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _aiSuggestedStatus.contains("Không") ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _aiSuggestedStatus.contains("Không") ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_aiSuggestedStatus.contains("Không") ? Icons.check_circle : Icons.warning_rounded, color: _aiSuggestedStatus.contains("Không") ? Colors.green : Colors.red, size: 28),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Kết quả AI:\n$_aiSuggestedStatus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _aiSuggestedStatus.contains("Không") ? Colors.green.shade800 : Colors.red.shade800))),
                          ],
                        ),
                      )
                    ],
                    const SizedBox(height: 24),
                    _modernTextField(_statusController, "Chẩn đoán lâm sàng", maxLines: 1),
                    const SizedBox(height: 16),
                    _modernTextField(_treatmentController, "Phác đồ điều trị / Lời khuyên", maxLines: 3),
                    const SizedBox(height: 32),

                    // 🛠️ HÀNG NÚT BẤM (GIỮ NGUYÊN FORM CŨ & THÊM NÚT KÊ ĐƠN RIÊNG LẺ)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleSaveAndPrescribe,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text("Ký & Lưu Bệnh Án", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14), // Khoảng cách giữa các hàng nút
                        
                        // 🍏 BUTTON RIÊNG BIỆT THÊM MỚI: MỞ THẲNG TRANG KÊ ĐƠN & TRUYỀN DATA
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _navigateToPrescriptionScreen,
                            icon: const Icon(Icons.medication_liquid, color: Colors.blue, size: 22),
                            label: const Text(
                              "Chỉ Kê Đơn Thuốc",
                              style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.blue.withOpacity(0.06), // Tạo nền xanh nhạt sang trọng
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernField(TextEditingController controller, String label, String unit) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: "$label ($unit)",
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        filled: true, fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      ),
      validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? "!" : null,
    );
  }

  Widget _modernTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập thông tin" : null,
    );
  }
}