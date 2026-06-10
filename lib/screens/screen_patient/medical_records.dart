import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import '../../providers/auth_provider.dart';
import 'medical_record_card.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> {
  final TextEditingController patientIdController = TextEditingController();
  List<Map<String, dynamic>> records = [];
  bool loading = false;
  bool isPatient = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadRecords();
    });
  }

  Future<void> _checkAndLoadRecords() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (authState.role.value == 'patient') {
        setState(() {
          isPatient = true;
          patientIdController.text = authState.userId ?? '';
        });
        await _fetchRecords(authState.userId ?? '');
      }
    }
  }

  Future<void> _fetchRecords(String patientId) async {
    if (patientId.isEmpty) return;

    setState(() => loading = true);

    try {
      final results = await MedicalRecordBlockchainService.searchMedicalRecordsByPatientId(patientId);
      setState(() {
        records = results;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải bệnh án: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _search() async {
    final patientId = patientIdController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Patient ID'), backgroundColor: Colors.orange),
      );
      return;
    }
    await _fetchRecords(patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Hồ Sơ Bệnh Án",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isPatient) ...[
                const Text(
                  "Tra cứu hồ sơ bệnh án",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: patientIdController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Nhập mã Patient ID...",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Icon(Icons.search, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (isPatient) ...[
                const Text(
                  "Bệnh án của bạn",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Danh sách hồ sơ bệnh án đã được lưu trữ an toàn trên blockchain",
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 16),
            Text(
              "Đang tải hồ sơ bệnh án...",
              style: TextStyle(color: _kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 72,
              color: _kTextSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              "Không tìm thấy hồ sơ bệnh án nào",
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPatient
                  ? "Bạn chưa có lịch sử khám bệnh nào tại hệ thống."
                  : "Vui lòng kiểm tra lại Patient ID và thử lại.",
              style: const TextStyle(color: _kTextSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return MedicalRecordCard(record: record);
      },
    );
  }
}
