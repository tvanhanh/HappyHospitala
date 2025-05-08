import 'package:flutter/material.dart';
import '../../services/api_aiService.dart'; // Đường dẫn đúng với dự án của bạn

class DiagnosisFormScreen extends StatefulWidget {
  const DiagnosisFormScreen({super.key});

  @override
  State<DiagnosisFormScreen> createState() => _DiagnosisFormScreenState();
}

class _DiagnosisFormScreenState extends State<DiagnosisFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường nhập
  String gender = 'F';
  final ageController = TextEditingController();
  final ureaController = TextEditingController();
  final crController = TextEditingController();
  final hba1cController = TextEditingController();
  final cholController = TextEditingController();
  final tgController = TextEditingController();
  final hdlController = TextEditingController();
  final ldlController = TextEditingController();
  final vldlController = TextEditingController();
  final bmiController = TextEditingController();

  String? diagnosisResult;

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final patientData = {
      "Gender": gender,
      "AGE": int.tryParse(ageController.text) ?? 0,
      "Urea": double.tryParse(ureaController.text) ?? 0,
      "Cr": double.tryParse(crController.text) ?? 0,
      "HbA1c": double.tryParse(hba1cController.text) ?? 0,
      "Chol": double.tryParse(cholController.text) ?? 0,
      "TG": double.tryParse(tgController.text) ?? 0,
      "HDL": double.tryParse(hdlController.text) ?? 0,
      "LDL": double.tryParse(ldlController.text) ?? 0,
      "VLDL": double.tryParse(vldlController.text) ?? 0,
      "BMI": double.tryParse(bmiController.text) ?? 0,
    };

    try {
      final response = await AIService.predictDisease(patientData);
      setState(() {
        diagnosisResult = response;
      });
    } catch (e) {
      setState(() {
        diagnosisResult = "⚠️ Lỗi kết nối server";
      });
    }
  }

  Widget buildTextField(String label, TextEditingController controller, {String? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Không được bỏ trống';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" Chẩn Đoán Bệnh")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: gender,
                items: ['M', 'F'].map((g) {
                return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (value) => setState(() => gender = value!),
                decoration: InputDecoration(labelText: 'Gender (M/F)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              buildTextField("Tuổi", ageController),
              const SizedBox(height: 12),
              buildTextField("Urea", ureaController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("Creatinine", crController, suffix: "µmol/L"),
              const SizedBox(height: 12),
              buildTextField("HbA1c", hba1cController, suffix: "%"),
              const SizedBox(height: 12),
              buildTextField("Cholesterol", cholController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("TG", tgController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("HDL", hdlController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("LDL", ldlController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("VLDL", vldlController, suffix: "mmol/L"),
              const SizedBox(height: 12),
              buildTextField("BMI", bmiController),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: submitForm,
                child: const Text(" Chẩn đoán"),
              ),
              const SizedBox(height: 20),

              if (diagnosisResult != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    "Kết quả: $diagnosisResult",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
