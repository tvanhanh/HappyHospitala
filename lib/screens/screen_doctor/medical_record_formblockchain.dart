import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import '../../models/appointment.dart';

class MedicalRecordForm extends StatefulWidget {
  const MedicalRecordForm({super.key, required this.appointment});

  final Appointment appointment;
  @override
  State<MedicalRecordForm> createState() => _MedicalRecordFormState();
  
}

class _MedicalRecordFormState extends State<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController cccdController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
final TextEditingController genderController = TextEditingController();
final TextEditingController phoneController = TextEditingController();
final TextEditingController addressController = TextEditingController();
final TextEditingController noteController = TextEditingController();
final TextEditingController prescriptionController = TextEditingController();
final TextEditingController testResultController = TextEditingController();
final TextEditingController followUpController = TextEditingController();
final TextEditingController blockchainStatusController =TextEditingController();
final TextEditingController editHistoryController = TextEditingController();

  DateTime? visitDate;
  bool _isLoading = false; // Biến theo dõi trạng thái đang gửi dữ liệu

  // Dùng XFile để hỗ trợ cả web và mobile
  final List<XFile> attachments = [];
  final ImagePicker picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    loadDoctorId();
    patientIdController.text = widget.appointment.id;
    patientNameController.text = widget.appointment.patientName;
    phoneController.text = widget.appointment.phone;
    doctorNameController.text = widget.appointment.doctorName;
  }

  Future<void> loadDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorId = prefs.getString('doctorId') ?? '';
    doctorIdController.text = doctorId;
  }

  Future<void> pickAttachments() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        attachments.addAll(pickedFiles);
      });
    }
  }
  Widget buildField({
  required String label,
  required TextEditingController controller,
  int maxLines = 1,
  bool readOnly = false,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    readOnly: readOnly,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo Hồ Sơ Bệnh Án"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

  // =====================================================
  // THÔNG TIN BỆNH NHÂN
  // =====================================================

  const Text(
    "Thông tin bệnh nhân",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 14),

  Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: patientIdController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: "Patient ID",
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value!.isEmpty
                  ? "Nhập Patient ID"
                  : null,
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: patientNameController,
          decoration: const InputDecoration(
            labelText: "Tên bệnh nhân",
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value!.isEmpty
                  ? "Nhập tên bệnh nhân"
                  : null,
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: cccdController,
          decoration: const InputDecoration(
            labelText: "CCCD",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: dobController,
          decoration: const InputDecoration(
            labelText: "Ngày sinh",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: genderController,
          decoration: const InputDecoration(
            labelText: "Giới tính",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: "Số điện thoại",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      SizedBox(
        width: 512,
        child: TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: "Địa chỉ",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 24),

  // =====================================================
  // THÔNG TIN BÁC SĨ
  // =====================================================

  const Text(
    "Thông tin bác sĩ",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 14),

  Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: doctorIdController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: "Doctor ID",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      SizedBox(
        width: 250,
        child: TextFormField(
          controller: doctorNameController,
          decoration: const InputDecoration(
            labelText: "Tên bác sĩ",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 24),

  // =====================================================
  // NGÀY KHÁM
  // =====================================================

  Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
    children: [

      Text(
        visitDate != null
            ? "Ngày khám: ${visitDate.toString().substring(0, 10)}"
            : "Chưa chọn ngày khám",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      ElevatedButton.icon(
        onPressed: () async {

          final date =
              await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );

          if (date != null) {
            setState(() {
              visitDate = date;
            });
          }
        },

        icon: const Icon(Icons.calendar_month),

        label: const Text("Chọn ngày"),
      ),
    ],
  ),

  const SizedBox(height: 24),

  // =====================================================
  // THÔNG TIN KHÁM
  // =====================================================

  const Text(
    "Thông tin khám bệnh",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 14),

  Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [

    SizedBox(
      width: 420,
      child: TextFormField(
        controller: symptomsController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Triệu chứng",
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) =>
            value!.isEmpty
                ? "Nhập triệu chứng"
                : null,
      ),
    ),

    SizedBox(
      width: 420,
      child: TextFormField(
        controller: diagnosisController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Chẩn đoán",
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) =>
            value!.isEmpty
                ? "Nhập chẩn đoán"
                : null,
      ),
    ),
  ],
),

const SizedBox(height: 14),

// ================= ĐIỀU TRỊ + ĐƠN THUỐC =================

Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [

    SizedBox(
      width: 420,
      child: TextFormField(
        controller: treatmentController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Phương pháp điều trị",
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) =>
            value!.isEmpty
                ? "Nhập điều trị"
                : null,
      ),
    ),

    SizedBox(
      width: 420,
      child: TextFormField(
        controller: prescriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Đơn thuốc",
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
  ],
),

const SizedBox(height: 14),

// ================= XÉT NGHIỆM + TÁI KHÁM =================

Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [

    SizedBox(
      width: 420,
      child: TextFormField(
        controller: testResultController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Kết quả xét nghiệm",
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),

    SizedBox(
      width: 420,
      child: Column(
        children: [

          TextFormField(
            controller: followUpController,
            decoration: InputDecoration(
              labelText: "Hẹn tái khám",
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: blockchainStatusController,
            decoration: InputDecoration(
              labelText: "Trạng thái hồ sơ",
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 14),

// ================= GHI CHÚ =================

TextFormField(
  controller: noteController,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: "Ghi chú bác sĩ",
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),

const SizedBox(height: 14),

// ================= LỊCH SỬ BLOCKCHAIN =================

TextFormField(
  controller: editHistoryController,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: "Lịch sử chỉnh sửa Blockchain",
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),
  const SizedBox(height: 24),
  const Text(
    "Tệp đính kèm (ảnh/X-ray)",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 12),

  Row(
    children: [

      ElevatedButton.icon(
        onPressed: pickAttachments,
        icon: const Icon(Icons.upload),
        label: const Text("Chọn tệp"),
      ),

      const SizedBox(width: 14),

      Text(
        "${attachments.length} tệp đã chọn",
      ),
    ],
  ),

  const SizedBox(height: 12),

  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: attachments.map((x) {

      return Chip(
        label: Text(
          p.basename(x.path),
        ),
      );
    }).toList(),
  ),

  const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Nếu đang loading thì disable nút (onPressed = null) để tránh nhấn nhiều lần
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate() &&
                              visitDate != null) {
                            // Bắt đầu hiệu ứng loading
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              // Gọi hàm xử lý Blockchain (mất ~33s)
                              await MedicalRecordBlockchainService
                                  .addMedicalRecord(
                                patientId: patientIdController.text.trim(),
                                doctorId: doctorIdController.text.trim(),
                                patientName: patientNameController.text.trim(),
                                symptoms: symptomsController.text.trim(),
                                diagnosis: diagnosisController.text.trim(),
                                treatment: treatmentController.text.trim(),
                                visitDate: visitDate!,
                                attachments: attachments,
                              );

                              // CHỈ HIỆN THÔNG BÁO KHI ĐÃ CHẠY XONG DÒNG TRÊN
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Tạo hồ sơ thành công trên Blockchain!")),
                                );
                                _formKey.currentState!.reset();
                                setState(() {
                                  visitDate = null;
                                  attachments.clear();
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lỗi: $e")),
                                );
                              }
                            } finally {
                              // Kết thúc loading dù thành công hay lỗi
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          } else if (visitDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Vui lòng chọn ngày khám")),
                            );
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Tạo Hồ Sơ"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
