import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_aiService.dart';

class DiagnosisFormScreen extends StatefulWidget {
  const DiagnosisFormScreen({super.key});

  @override
  State<DiagnosisFormScreen> createState() => _DiagnosisFormScreenState();
}

class _DiagnosisFormScreenState extends State<DiagnosisFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ===== INPUT =====
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

  Map<String, dynamic>? diagnosisResult;

  // ===== CSV =====
  List<List<dynamic>> dataset = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  String formatResult(dynamic data) {
    if (data == null) return "";

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return formatResult(decoded);
      } catch (_) {
        // fallback: chỉ xoá {} nếu chắc chắn là string rác
        return data.replaceAll(RegExp(r'[{}]'), '').trim();
      }
    }

    if (data is Map) {
      return data.entries.map((e) {
        if (e.key.toString().toLowerCase().contains("Xác suất")) {
          return "${e.key}:\n${e.value}";
        }
        return "${e.key}: ${e.value}";
      }).join("\n\n");
    }
    if (data is List) {
      return data.map((e) => formatResult(e)).join("\n");
    }

    return data.toString();
  }

  // 📥 LOAD CSV
  Future<void> loadCSV() async {
    final rawData = await rootBundle.loadString("assets/diabetes_test.csv");
    print("LOAD OK");
    print(rawData.substring(0, 100));
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    listData.removeAt(0);

    setState(() {
      dataset = listData;
      currentIndex = 0;
    });
  }

  // 🎯 NEXT PATIENT (THEO THỨ TỰ)
  void fillNextFromCSV() {
    if (dataset.isEmpty) return;

    setState(() {
      // 👉 nếu chưa click lần nào
      if (currentIndex < 0) {
        currentIndex = 0;
      }
      // 👉 tăng bình thường
      else {
        currentIndex++;
        if (currentIndex >= dataset.length) {
          currentIndex = 0;
        }
      }

      final row = dataset[currentIndex];

      gender = row[0] == 0 ? "F" : "M";
      ageController.text = row[1].toString();
      ureaController.text = row[2].toString();
      crController.text = row[3].toString();
      hba1cController.text = row[4].toString();
      cholController.text = row[5].toString();
      tgController.text = row[6].toString();
      hdlController.text = row[7].toString();
      ldlController.text = row[8].toString();
      vldlController.text = row[9].toString();
      bmiController.text = row[10].toString();
    });
  }

  // 🤖 PREDICT
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
        if (response.containsKey('error')) {
          diagnosisResult = {'prediction_label': '⚠️ Lỗi: ${response['error']}', 'error': true};
        } else {
          diagnosisResult = response;
        }
      });
    } catch (e) {
      setState(() {
        diagnosisResult = {'prediction_label': '⚠️ Lỗi kết nối server', 'error': true};
      });
    }
  }

  // 📌 TEXT FIELD
  Widget buildTextField(String label, TextEditingController controller,
      {String? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Chẩn Đoán Bệnh"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🎯 NEXT BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: fillNextFromCSV,
                  icon: const Icon(Icons.skip_next),
                  label: Text(
                    dataset.isEmpty
                        ? "0/0"
                        : currentIndex < 0
                            ? "0/${dataset.length}"
                            : "${currentIndex + 1}/${dataset.length}",
                  ),
                ),
              ),

              DropdownButtonFormField<String>(
                value: gender,
                items: ['M', 'F']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => gender = value!),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),
              buildTextField("Tuổi", ageController),
              const SizedBox(height: 12),
              buildTextField("Urea", ureaController),
              const SizedBox(height: 12),
              buildTextField("Creatinine", crController),
              const SizedBox(height: 12),
              buildTextField("HbA1c", hba1cController),
              const SizedBox(height: 12),
              buildTextField("Cholesterol", cholController),
              const SizedBox(height: 12),
              buildTextField("TG", tgController),
              const SizedBox(height: 12),
              buildTextField("HDL", hdlController),
              const SizedBox(height: 12),
              buildTextField("LDL", ldlController),
              const SizedBox(height: 12),
              buildTextField("VLDL", vldlController),
              const SizedBox(height: 12),
              buildTextField("BMI", bmiController),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitForm,
                  child: const Text("Chẩn đoán"),
                ),
              ),

              const SizedBox(height: 20),
              if (diagnosisResult != null)
                Builder(builder: (context) {
                  final res = diagnosisResult!;
                  final bool hasError = res['error'] == true;
                  final String label = (res['prediction_label'] ?? res['prediction'] ?? '').toString();
                  final bool isNormal = label.contains('Không mắc');
                  final bool isWho    = res['rule_triggered'] == true;
                  final Map<String, dynamic> probs = res['probabilities'] is Map
                      ? Map<String, dynamic>.from(res['probabilities'] as Map)
                      : {};
                  final String advice = (res['clinical_advice'] ?? '').toString();

                  double parsePct(String? s) =>
                      double.tryParse((s ?? '').replaceAll('%', '').trim()) ?? 0.0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasError
                          ? Colors.orange.shade50
                          : isNormal
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError
                            ? Colors.orange
                            : isNormal
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              hasError
                                  ? Icons.error_outline
                                  : isNormal
                                      ? Icons.check_circle
                                      : Icons.warning,
                              color: hasError
                                  ? Colors.orange
                                  : isNormal
                                      ? Colors.green
                                      : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kết quả chẩn đoán AI',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    label.isNotEmpty ? label : 'Không xác định',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isNormal
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isWho)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('WHO ≥6.5%',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (probs.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Xác suất (Custom KNN)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 8),
                          _buildBar('Bình thường',   parsePct(probs['Normal']?.toString()),     const Color(0xFF22C55E)),
                          const SizedBox(height: 6),
                          _buildBar('Tiền tiểu đường', parsePct(probs['Prediabetes']?.toString()), const Color(0xFFF59E0B)),
                          const SizedBox(height: 6),
                          _buildBar('Tiểu đường',    parsePct(probs['Diabetes']?.toString()),    const Color(0xFFEF4444)),
                        ],
                        if (advice.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 6),
                          Text(advice,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double pct, Color color) {
    final double fraction = (pct / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
            Text('${pct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        LayoutBuilder(builder: (ctx, constraints) {
          return Stack(children: [
            Container(height: 7, width: constraints.maxWidth,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
            Container(height: 7, width: constraints.maxWidth * fraction,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ]);
        }),
      ],
    );
  }
}
