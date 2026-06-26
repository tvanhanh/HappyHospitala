import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/appointment.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import '../../services/api_appointment.dart';
import '../../services/config.dart';
import 'PrescriptionScreen.dart';

class EmrSkinCancerFormWidget extends StatefulWidget {
  final Appointment appointment;
  final int Function(String) calculateAge;
  final String Function(String) formatDateToDdMmYyyy;
  final VoidCallback onSuccess;

  const EmrSkinCancerFormWidget({
    super.key,
    required this.appointment,
    required this.calculateAge,
    required this.formatDateToDdMmYyyy,
    required this.onSuccess,
  });

  @override
  State<EmrSkinCancerFormWidget> createState() => _EmrSkinCancerFormWidgetState();
}

class _EmrSkinCancerFormWidgetState extends State<EmrSkinCancerFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  double _age = 50.0;
  String _sex = 'unknown';
  String _localization = 'unknown';

  final _statusController = TextEditingController();
  final _treatmentController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isAIPredicting = false;
  Map<String, dynamic>? _result;
  String? _error;

  final List<String> _localizations = [
    'abdomen', 'back', 'chest', 'ear', 'face', 'foot', 'genital', 
    'hand', 'lower extremity', 'neck', 'scalp', 'trunk', 'upper extremity', 'unknown'
  ];

  final Map<String, String> _localizationNames = {
    'abdomen': 'Bụng',
    'back': 'Lưng',
    'chest': 'Ngực',
    'ear': 'Tai',
    'face': 'Mặt',
    'foot': 'Bàn chân',
    'genital': 'Cơ quan sinh dục',
    'hand': 'Bàn tay',
    'lower extremity': 'Chi dưới (Chân)',
    'neck': 'Cổ',
    'scalp': 'Da đầu',
    'trunk': 'Thân mình',
    'upper extremity': 'Chi trên (Tay)',
    'unknown': 'Không xác định'
  };

  final Map<String, String> _diseaseNames = {
    'akiec': 'Bệnh dày sừng quang hóa (AKIEC)',
    'bcc': 'Ung thư biểu mô tế bào đáy (BCC)',
    'bkl': 'Dày sừng tiết bã (BKL)',
    'df': 'U xơ da (DF)',
    'mel': 'Ung thư hắc tố (Melanoma - MEL)',
    'nv': 'Nốt ruồi (NV)',
    'vasc': 'Tổn thương mạch máu (VASC)'
  };

  @override
  void initState() {
    super.initState();
    // Khởi tạo thông tin bệnh nhân
    int calcAge = widget.calculateAge(widget.appointment.birthDate);
    if (calcAge > 0 && calcAge <= 100) {
      _age = calcAge.toDouble();
    }
    String genderStr = widget.appointment.gender.toLowerCase();
    if (genderStr.contains('nam')) {
      _sex = 'male';
    } else if (genderStr.contains('nữ') || genderStr.contains('nu')) {
      _sex = 'female';
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> _runAIPrediction() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải ảnh tổn thương da trước khi phân tích.')),
      );
      return;
    }

    setState(() {
      _isAIPredicting = true;
      _error = null;
      _result = null;
    });

    try {
      final uri = Uri.parse(baseUrl);
      final aiBaseUrl = '${uri.scheme}://${uri.host}:5000';
      
      final request = http.MultipartRequest('POST', Uri.parse('$aiBaseUrl/api/predict_skin'));
      
      request.fields['age'] = _age.toString();
      request.fields['sex'] = _sex;
      request.fields['localization'] = _localization;

      final bytes = await _selectedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: _selectedImage!.name.isNotEmpty ? _selectedImage!.name : 'image.jpg',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _result = data['data'];
            _isAIPredicting = false;
            
            // Tự động điền chẩn đoán và điều trị
            String diagnosisKey = _result!['diagnosis'];
            String diagnosisName = _diseaseNames[diagnosisKey] ?? diagnosisKey.toUpperCase();
            _statusController.text = diagnosisName;
            _treatmentController.text = _result!['medical_recommendation'] ?? "";
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Lỗi không xác định';
            _isAIPredicting = false;
          });
        }
      } else {
        setState(() {
          _error = 'Lỗi kết nối máy chủ AI: ${response.statusCode}\n${response.body}';
          _isAIPredicting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối máy chủ AI.\nVui lòng kiểm tra xem Backend AI đã được bật ở cổng 5000 chưa.\nChi tiết: $e';
        _isAIPredicting = false;
      });
    }
  }

  void _navigateToPrescriptionScreen() {
    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionScreen(
          appointment: widget.appointment,
          diagnosis: _statusController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _handleSaveAndPrescribe() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Nếu chưa có ảnh thì lấy reason làm symptoms
    String symptoms = widget.appointment.reason.isNotEmpty ? widget.appointment.reason : "Không ghi nhận";
    if (_selectedImage != null) {
      symptoms = "[Da Liễu] Bệnh nhân có tổn thương vùng ${_localizationNames[_localization]}. $symptoms";
    }

    setState(() => _isSubmitting = true);

    try {
      final deptName = widget.appointment.departmentName.isNotEmpty
          ? widget.appointment.departmentName
          : (widget.appointment.doctorSpecialty.isNotEmpty 
              ? widget.appointment.doctorSpecialty 
              : "Da liễu");

      await MedicalRecordBlockchainService.addMedicalRecord(
        patientId: widget.appointment.patientId,
        doctorId: widget.appointment.doctorId,
        patientName: widget.appointment.patientName,
        symptoms: symptoms,
        visitDate: DateTime.tryParse(widget.appointment.date) ?? DateTime.now(),
        diagnosis: _statusController.text.trim(),
        treatment: _treatmentController.text.trim(),
        attachments: _selectedImage != null ? [_selectedImage!] : [],
        departmentName: deptName,
        doctorName: widget.appointment.doctorName,
      );

      if (!mounted) return;

      // Thành công thì tiếp tục cập nhật trạng thái lịch hẹn
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
                "Bệnh án EMR (Da liễu) đã được lưu thành công!\nBạn có muốn tiến hành kê đơn thuốc cho bệnh nhân này luôn không?",
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi hệ thống xảy ra: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                    const Text("Bệnh Án Da Liễu AI",
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
                    // CẢNH BÁO Y TẾ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'AI chỉ hỗ trợ Bác sĩ đưa ra dự đoán tham khảo về tình trạng tổn thương trên da.',
                              style: TextStyle(fontSize: 13, color: Colors.brown),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TẢI ẢNH LÊN
                    const Text('1. Hình ảnh tổn thương da', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Chọn từ thư viện'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                                if (!kIsWeb)
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Chụp ảnh mới'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.none),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb 
                                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Bấm để chọn ảnh hoặc chụp mới', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // THÔNG TIN BỆNH ÁN
                    const Text('2. Thông tin bệnh án (Đa phương thức)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tuổi
                          Row(
                            children: [
                              const Icon(Icons.cake_rounded, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Text('Độ tuổi: ${_age.toInt()}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Slider(
                            value: _age,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            activeColor: const Color(0xFF2563EB),
                            onChanged: (val) => setState(() => _age = val),
                          ),
                          const Divider(),
                          
                          // Giới tính
                          Row(
                            children: [
                              const Icon(Icons.people_rounded, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              DropdownButton<String>(
                                value: _sex,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'unknown', child: Text('Không xác định')),
                                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                ],
                                onChanged: (val) => setState(() => _sex = val!),
                              ),
                            ],
                          ),
                          const Divider(),

                          // Vị trí
                          Row(
                            children: [
                              const Icon(Icons.accessibility_new_rounded, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              const Text('Vị trí tổn thương:', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _localization,
                                items: _localizations.map((loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text(_localizationNames[loc] ?? loc),
                                )).toList(),
                                onChanged: (val) => setState(() => _localization = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // NÚT PHÂN TÍCH AI
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isAIPredicting ? null : _runAIPrediction,
                        icon: _isAIPredicting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.document_scanner, color: Colors.white),
                        label: Text(_isAIPredicting ? "AI đang phân tích..." : "Phân tích bằng AI", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: const Color(0xFFDC2626).withOpacity(0.5)),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      )
                    ],

                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _result!['has_cancer_risk'] == true ? Colors.red.shade50 : (_result!['confidence_percent'] > 70 ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _result!['has_cancer_risk'] == true ? Colors.red.shade300 : (_result!['confidence_percent'] > 70 ? const Color(0xFF86EFAC) : const Color(0xFFFDBA74))),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _result!['has_cancer_risk'] == true ? Icons.warning_rounded : (_result!['confidence_percent'] > 70 ? Icons.check_circle : Icons.info_outline), 
                              color: _result!['has_cancer_risk'] == true ? Colors.red : (_result!['confidence_percent'] > 70 ? Colors.green : Colors.orange), 
                              size: 28
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _result!['has_cancer_risk'] == true ? "CẢNH BÁO ÁC TÍNH TIỀM ẨN!" : "Kết quả AI dự đoán:", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _result!['has_cancer_risk'] == true ? Colors.red.shade800 : Colors.grey.shade700)
                                ),
                                const SizedBox(height: 12),
                                if (_result!['top_3_predictions'] != null)
                                  ...(_result!['top_3_predictions'] as List).map((item) {
                                    final diagKey = item['diagnosis'];
                                    final conf = item['confidence_percent'];
                                    final isCancer = ['mel', 'bcc', 'akiec'].contains(diagKey);
                                    final isHighRisk = isCancer && conf > 15;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _diseaseNames[diagKey] ?? diagKey.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: isHighRisk ? FontWeight.bold : FontWeight.w500,
                                                color: isHighRisk ? Colors.red.shade800 : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isHighRisk ? Colors.red.shade100 : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6)
                                            ),
                                            child: Text(
                                              "$conf%",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isHighRisk ? Colors.red.shade800 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()
                                else
                                  Text(_diseaseNames[_result!['diagnosis']] ?? _result!['diagnosis'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _result!['confidence_percent'] > 70 ? Colors.green.shade800 : Colors.orange.shade800)),
                              ],
                            )),
                          ],
                        ),
                      )
                    ],

                    const SizedBox(height: 24),
                    _modernTextField(_statusController, "Chẩn đoán lâm sàng", maxLines: 1),
                    const SizedBox(height: 16),
                    _modernTextField(_treatmentController, "Phác đồ điều trị / Lời khuyên", maxLines: 3),
                    const SizedBox(height: 32),

                    // HÀNG NÚT BẤM
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
                        const SizedBox(height: 14), 
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
                              backgroundColor: Colors.blue.withOpacity(0.06), 
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
