import 'package:flutter/material.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import 'medical_record_card.dart';

class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final TextEditingController patientIdController = TextEditingController();
  List<Map<String, dynamic>> records = [];
  bool loading = false;

  Future<void> search() async {
    final patientId = patientIdController.text.trim();
    if (patientId.isEmpty) return;

    setState(() => loading = true);

    records =
        await MedicalRecordBlockchainService.searchMedicalRecordsByPatientId(patientId);

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tra cứu bệnh án")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔍 SEARCH BAR
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: patientIdController,
                    decoration: const InputDecoration(
                      labelText: "Nhập mã Patient ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: search,
                  child: const Icon(Icons.search),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 📄 RESULT
            if (loading)
              const CircularProgressIndicator()
            else if (records.isEmpty)
              const Text("Chưa có dữ liệu")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return MedicalRecordCard(record: r);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
