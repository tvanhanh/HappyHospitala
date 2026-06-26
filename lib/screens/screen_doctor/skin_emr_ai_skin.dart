import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/appointment.dart';
import '../../services/api_aiService.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_appointment.dart';
import 'PrescriptionScreen.dart';

class SkinEmrAiFormWidget extends StatefulWidget {
  final Appointment appointment;
  final int Function(String) calculateAge;
  final String Function(String) formatDateToDdMmYyyy;
  final VoidCallback onSuccess;

  const SkinEmrAiFormWidget({
    super.key,
    required this.appointment,
    required this.calculateAge,
    required this.formatDateToDdMmYyyy,
    required this.onSuccess,
  });

  @override
  State<SkinEmrAiFormWidget> createState() => _SkinEmrAiFormWidgetState();
}

class _SkinEmrAiFormWidgetState extends State<SkinEmrAiFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _statusController = TextEditingController();
  final _treatmentController = TextEditingController();

  bool _isSubmitting = false;
  bool _isAIPredicting = false;

  // AI & Image Data
  File? _selectedImage;
  String? _aiDiagnosisResult;
  String _aiSuggestedStatus = "Đang chờ phân tích...";
  double _aiConfidence = 0.0;

  // Dropdown Selections (Khớp với dữ liệu HAM10000)
  String _selectedGender = 'unknown';
  String _selectedLocalization = 'unknown';

  final List<String> _genderOptions = ['male', 'female', 'unknown'];
  final List<String> _localizationOptions = [
    'back',
    'lower extremity',
    'trunk',
    'upper extremity',
    'abdomen',
    'face',
    'chest',
    'foot',
    'unknown',
    'neck',
    'scalp',
    'hand',
    'ear',
    'genital',
    'acral'
  ];

  @override
  void initState() {
    super.initState();
    _autoFillPatientInfo();
  }

  void _autoFillPatientInfo() {
    String gender = widget.appointment.gender.toLowerCase();
    if (gender.contains('nam')) {
      _selectedGender = 'male';
    } else if (gender.contains('nữ')) {
      _selectedGender = 'female';
    } else {
      _selectedGender = 'unknown';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // Reset kết quả AI cũ nếu chọn ảnh mới
        _aiDiagnosisResult = null;
        _statusController.clear();
      });
    }
  }

  Future<void> _runAIPrediction() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vui lòng tải ảnh chụp tổn thương da lên trước!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAIPredicting = true);

    final int age = widget.calculateAge(widget.appointment.birthDate);
    final double finalAge = age > 0 ? age.toDouble() : 50.0;

    // try {
    //   // GỌI API GỬI ẢNH VÀ DỮ LIỆU SANG FLASK BACKEND
    //   // Ông cần tự viết hàm predictSkinDisease trong AIService nhận tham số là (File, age, sex, localization)
    //   final response = await AIService.predictSkinDisease(
    //     imageFile: _selectedImage!,
    //     age: finalAge,
    //     sex: _selectedGender,
    //     localization: _selectedLocalization,
    //   );

    //   if (!mounted) return;

    //   // Xử lý JSON trả về từ Flask
    //   if (response['status'] == 'success') {
    //     final data = response['data'];
    //     setState(() {
    //       _aiDiagnosisResult = data['diagnosis_code'];
    //       _aiConfidence = data['confidence_percent'];
    //       _aiSuggestedStatus = data['diagnosis_code'].toString().toUpperCase();

    //       _statusController.text =
    //           "Chẩn đoán hình ảnh AI: $_aiSuggestedStatus (Độ tin cậy: $_aiConfidence%)";
    //       _treatmentController.text = data['medical_recommendation'] ?? "";
    //     });
    //   } else {
    //     throw Exception(response['message']);
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text("Lỗi phân tích AI: $e")));
    // } finally {
    //   if (mounted) setState(() => _isAIPredicting = false);
    // }
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
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Chưa có ảnh hồ sơ bệnh án!"),
          backgroundColor: Colors.red));
      return;
    }

    // Logic lưu bệnh án tương tự Form Tiểu đường của ông
    // Nhớ cấu trúc lại MedicalRecordService để lưu url ảnh (hoặc hash IPFS) nếu cần
    // ... (Giữ nguyên logic của ông) ...
  }

  @override
  void dispose() {
    _statusController.dispose();
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
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
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Khám Da Liễu AI",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KHU VỰC 1: INPUT ĐA PHƯƠNG THỨC (ẢNH + METADATA)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 20)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Dữ liệu đầu vào lâm sàng",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569))),
                          const SizedBox(height: 16),

                          // Khung Upload Ảnh
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.shade300,
                                    style: BorderStyle.solid),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(_selectedImage!,
                                          fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_a_photo,
                                            size: 40, color: Colors.blue),
                                        SizedBox(height: 8),
                                        Text("Tải ảnh từ kính Dermatoscope",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Metadata Dropdowns
                          Row(
                            children: [
                              Expanded(
                                  child: _buildDropdown(
                                      "Giới tính",
                                      _genderOptions,
                                      _selectedGender,
                                      (val) => setState(
                                          () => _selectedGender = val!))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildDropdown(
                                      "Vị trí U da",
                                      _localizationOptions,
                                      _selectedLocalization,
                                      (val) => setState(
                                          () => _selectedLocalization = val!))),
                            ],
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.document_scanner,
                                color: Colors.white),
                        label: Text(
                            _isAIPredicting
                                ? "AI đang quét ảnh..."
                                : "Phân tích U da bằng AI",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                      ),
                    ),

                    // KẾT QUẢ AI
                    if (_aiDiagnosisResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _aiSuggestedStatus == 'NV' ||
                                  _aiSuggestedStatus == 'BKL'
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _aiSuggestedStatus == 'NV' ||
                                      _aiSuggestedStatus == 'BKL'
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                _aiSuggestedStatus == 'NV' ||
                                        _aiSuggestedStatus == 'BKL'
                                    ? Icons.verified
                                    : Icons.warning_rounded,
                                color: _aiSuggestedStatus == 'NV' ||
                                        _aiSuggestedStatus == 'BKL'
                                    ? Colors.green
                                    : Colors.red,
                                size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    "Báo cáo AI: U da loại $_aiSuggestedStatus\nĐộ tin cậy: $_aiConfidence%",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _aiSuggestedStatus == 'NV' ||
                                                _aiSuggestedStatus == 'BKL'
                                            ? Colors.green.shade800
                                            : Colors.red.shade800))),
                          ],
                        ),
                      )
                    ],
                    const SizedBox(height: 24),

                    // KHU VỰC CHUYÊN MÔN CỦA BÁC SĨ
                    _modernTextField(
                        _statusController, "Chẩn đoán lâm sàng cuối cùng",
                        maxLines: 2),
                    const SizedBox(height: 16),
                    _modernTextField(
                        _treatmentController, "Phác đồ điều trị / Lời khuyên",
                        maxLines: 3),
                    const SizedBox(height: 32),

                    // NÚT BẤM (Giữ nguyên cấu trúc của ông)
                    // ... (Phần nút Hủy / Lưu / Kê đơn y hệt như Form Tiểu đường) ...
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Dropdown tiện lợi
  Widget _buildDropdown(String label, List<String> items, String currentValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _modernTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
