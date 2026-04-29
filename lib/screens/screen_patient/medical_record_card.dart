import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const MedicalRecordCard({super.key, required this.record});

  Future<void> downloadPdf() async {
    final url = record['pdfUrl'];
    if (url == null) return;

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isTampered = record['isTampered'] == true;

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
              record['patientName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text("Patient ID: ${record['patientId']}"),
            Text("Doctor ID: ${record['doctorId']}"),
            Text(
              "Ngày khám: ${record['visitDate'].toString().substring(0, 10)}",
            ),

            const Divider(height: 24),

            /// 🔐 INTEGRITY STATUS
            Row(
              children: [
                Icon(
                  isTampered
                      ? Icons.warning_amber_rounded
                      : Icons.verified,
                  color: isTampered ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isTampered
                      ? "Dữ liệu đã bị thay đổi"
                      : "Dữ liệu toàn vẹn (Blockchain verified)",
                  style: TextStyle(
                    color: isTampered ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔗 BLOCKCHAIN INFO
            const Text(
              "Blockchain",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Network: ${record['blockchainNetwork'] ?? '—'}"),
            Text("Block: ${record['blockNumber'] ?? '—'}"),
            const SizedBox(height: 4),
            const Text("Transaction hash:"),
            SelectableText(
              record['blockchainTx'] ?? '—',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 16),

            /// 🔘 ACTIONS
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
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
