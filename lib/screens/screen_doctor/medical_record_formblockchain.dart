import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../services/api_medicalRecordBlockchain.dart';

class MedicalRecordForm extends StatefulWidget {
  const MedicalRecordForm({super.key});

  @override
  State<MedicalRecordForm> createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends State<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();

  DateTime? visitDate;

  // Dùng XFile để hỗ trợ cả web và mobile
  final List<XFile> attachments = [];
  final ImagePicker picker = ImagePicker();

  Future<void> pickAttachments() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        attachments.addAll(pickedFiles);
      });
    }
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
              // Patient ID
              TextFormField(
                controller: patientIdController,
                decoration: const InputDecoration(
                  labelText: "Patient ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Nhập Patient ID" : null,
              ),
              const SizedBox(height: 14),

              // Doctor ID
              TextFormField(
                controller: doctorIdController,
                decoration: const InputDecoration(
                  labelText: "Doctor ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Nhập Doctor ID" : null,
              ),
              const SizedBox(height: 14),

              // Visit Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ngày khám: ${visitDate != null ? visitDate.toString().substring(0, 10) : 'Chưa chọn'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => visitDate = date);
                      }
                    },
                    child: const Text("Chọn ngày"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Symptoms
              TextFormField(
                controller: symptomsController,
                decoration: const InputDecoration(
                  labelText: "Triệu chứng",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Nhập triệu chứng" : null,
              ),
              const SizedBox(height: 14),

              // Diagnosis
              TextFormField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                  labelText: "Chẩn đoán",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Nhập chẩn đoán" : null,
              ),
              const SizedBox(height: 14),

              // Treatment
              TextFormField(
                controller: treatmentController,
                decoration: const InputDecoration(
                  labelText: "Điều trị",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? "Nhập phương pháp điều trị" : null,
              ),
              const SizedBox(height: 20),

              // Upload attachments
              const Text("Tệp đính kèm (ảnh/X-ray):"),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: pickAttachments,
                child: const Text("Chọn tệp"),
              ),
              const SizedBox(height: 10),

              // Show selected files
              ...attachments.map(
                (x) => Text("• ${p.basename(x.path)}"),
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        visitDate != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đang gửi dữ liệu...")),
                      );
                      try {
                        await MedicalRecordBlockchainService.addMedicalRecord(
                          patientId: patientIdController.text.trim(),
                          doctorId: doctorIdController.text.trim(),
                          symptoms: symptomsController.text.trim(),
                          diagnosis: diagnosisController.text.trim(),
                          treatment: treatmentController.text.trim(),
                          visitDate: visitDate!,
                          attachments: attachments, 
                         
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Tạo hồ sơ thành công!")),
                        );
                        _formKey.currentState!.reset();
                        setState(() {
                          visitDate = null;
                          attachments.clear();
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi: $e")),
                        );
                      }
                    } else if (visitDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Vui lòng chọn ngày khám")),
                      );
                    }
                  },
                  child: const Text("Tạo Hồ Sơ"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
