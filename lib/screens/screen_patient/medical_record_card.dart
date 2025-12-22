import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordCard extends StatefulWidget {
  final Map<String, dynamic> record;

  const MedicalRecordCard({super.key, required this.record});

  @override
  State<MedicalRecordCard> createState() => _MedicalRecordCardState();
}

class _MedicalRecordCardState extends State<MedicalRecordCard> {
  bool verifying = false;
  bool? isValid;

  Future<void> verify() async {
    setState(() {
      verifying = true;
      isValid = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      verifying = false;
      isValid = widget.record['blockchainTx'] != null;
    });
  }

  Future<void> downloadPdf() async {
    final url = widget.record['pdfUrl'];
    if (url == null) return;

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🧾 HEADER
            Text(
              r['patientName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text("Patient ID: ${r['patientId']}"),
            Text("Doctor ID: ${r['doctorId']}"),
            Text(
              "Ngày khám: ${r['visitDate'].toString().substring(0, 10)}",
            ),

            const Divider(height: 24),

            /// 🔗 BLOCKCHAIN
            const Text(
              "Blockchain",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Network: ${r['blockchainNetwork'] ?? '—'}"),
            Text("Block: ${r['blockNumber'] ?? '—'}"),
            const SizedBox(height: 4),
            const Text("Tx hash:"),
            SelectableText(
              r['blockchainTx'] ?? '—',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 16),

            /// ✅ VERIFY RESULT
            if (verifying)
              const CircularProgressIndicator()
            else if (isValid != null)
              Text(
                isValid!
                    ? "🟢 Dữ liệu KHÔNG bị thay đổi"
                    : "🔴 Dữ liệu đã bị chỉnh sửa",
                style: TextStyle(
                  color: isValid! ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 12),

            /// 🔘 ACTIONS
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text("Kiểm tra"),
                  onPressed: verify,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Tải PDF"),
                  onPressed: downloadPdf,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
