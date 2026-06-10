import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kSuccess = Color(0xFF10B981);
const Color _kWarning = Color(0xFFEF4444);

class MedicalRecordCard extends StatefulWidget {
  final Map<String, dynamic> record;

  const MedicalRecordCard({super.key, required this.record});

  @override
  State<MedicalRecordCard> createState() => _MedicalRecordCardState();
}

class _MedicalRecordCardState extends State<MedicalRecordCard> {
  bool _isExpanded = false;

  Future<void> _downloadPdf() async {
    final url = widget.record['pdfUrl'];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đường dẫn PDF của bệnh án này.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở liên kết: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã giao dịch vào bộ nhớ tạm!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(dynamic visitDate) {
    if (visitDate == null) return "N/A";
    try {
      final parsed = DateTime.parse(visitDate.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return visitDate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTampered = widget.record['isTampered'] == true;
    final doctorName = widget.record['doctorName'] ?? "Bác sĩ của Smart Clinic";
    final symptoms = widget.record['symptoms'] ?? "Không có ghi nhận";
    final diagnosis = widget.record['diagnosis'] ?? "Không có ghi nhận";
    final treatment = widget.record['treatment'] ?? "Không có ghi nhận";
    final visitDateStr = _formatDate(widget.record['visitDate']);
    final txHash = widget.record['blockchainTx'] ?? '';
    final blockNum = widget.record['blockNumber'] ?? '';
    final network = widget.record['blockchainNetwork'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTampered ? _kWarning.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isTampered ? _kWarning.withValues(alpha: 0.1) : _kSuccess.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    isTampered ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: isTampered ? _kWarning : _kSuccess,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTampered ? "DỮ LIỆU BỊ THAY ĐỔI (CẢNH BÁO)" : "XÁC THỰC BLOCKCHAIN (TOÀN VẸN)",
                      style: TextStyle(
                        color: isTampered ? _kWarning : _kSuccess,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: _kTextSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  visitDateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text("Tải PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary.withValues(alpha: 0.1),
                          foregroundColor: _kPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildClinicalRow("Triệu chứng lâm sàng", symptoms, Icons.sick_outlined),
                  const SizedBox(height: 12),
                  _buildClinicalRow("Chẩn đoán y khoa", diagnosis, Icons.assignment_outlined),
                  const SizedBox(height: 12),
                  _buildClinicalRow("Phác đồ điều trị", treatment, Icons.healing_outlined),
                  const Divider(height: 24, thickness: 1),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link_rounded, size: 18, color: _kPrimary),
                              SizedBox(width: 8),
                              Text(
                                "Xem chi tiết Blockchain",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: _kPrimary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBlockchainInfoRow("Mạng lưới", network.isNotEmpty ? network : "Local/Smart-Chain"),
                          const SizedBox(height: 6),
                          _buildBlockchainInfoRow("Block", blockNum.toString().isNotEmpty ? blockNum.toString() : "—"),
                          const SizedBox(height: 6),
                          const Text(
                            "Mã giao dịch (TxHash):",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  txHash.isNotEmpty ? txHash : "—",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (txHash.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(txHash),
                                  child: const Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: _kTextSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kTextPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTextSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _kTextPrimary,
          ),
        ),
      ],
    );
  }
}
