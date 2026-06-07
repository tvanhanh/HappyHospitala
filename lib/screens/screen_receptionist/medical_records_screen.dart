import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../services/api_medicalRecord.dart';

const kPrimaryColor = Color(0xFF0D47A1);
const kSecondaryColor = Color(0xFF1976D2);
const kBackgroundColor = Color(0xFFF5F7FA);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF333333);

// Riverpod Provider to fetch medical records from the database
final medicalRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await MedicalRecordService.getMedicalRecord();
});

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final bool showDrawer;
  const MedicalRecordsScreen({
    super.key,
    this.showAppBar = true,
    this.showDrawer = true,
  });

  @override
  ConsumerState<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  String _searchQuery = '';
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncRecords = ref.watch(medicalRecordsProvider);

    final mainBody = asyncRecords.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 12),
                Text("Lỗi tải hồ sơ bệnh án: $err", style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          data: (records) {
            // Filter records locally by search query
            final filtered = records.where((e) {
              final query = _searchQuery.toLowerCase();
              final name = e['patientName']?.toString().toLowerCase() ?? '';
              final email = e['email']?.toString().toLowerCase() ?? '';
              final symptoms = e['symptoms']?.toString().toLowerCase() ?? '';
              final diagnosis = e['diagnosis']?.toString().toLowerCase() ?? '';
              return name.contains(query) ||
                  email.contains(query) ||
                  symptoms.contains(query) ||
                  diagnosis.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildSearchBox(),
                    const SizedBox(height: 40),
                    const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Không tìm thấy hồ sơ bệnh án nào",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Nhập từ khóa khác hoặc bấm nút làm mới ở góc phải để thử lại.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Keep selected index within bounds
            if (_selectedIndex >= filtered.length) {
              _selectedIndex = 0;
            }

            final selectedRecord = filtered[_selectedIndex];
            final patientEmail = selectedRecord['email']?.toString() ?? '';

            // Filter history records for the same patient
            final patientHistory = records.where((r) => r['email']?.toString() == patientEmail).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 20),
                  _buildPatientListDropdown(filtered),
                  const SizedBox(height: 20),
                  _buildPatientSummary(selectedRecord),
                  const SizedBox(height: 20),
                  _buildTabs(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _buildPatientInfo(selectedRecord),
                        _buildVisitHistory(patientHistory),
                        _buildLabResults(selectedRecord),
                        _buildPrescriptions(selectedRecord),
                        _buildImages(selectedRecord),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text(
                  "Hồ Sơ Bệnh Án",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: kPrimaryColor,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      ref.invalidate(medicalRecordsProvider);
                    },
                  )
                ],
              )
            : null,
        drawer: widget.showDrawer
            ? const ReceptionistDrawer(
                selectedMenu: "Hồ sơ bệnh án",
              )
            : null,
        body: mainBody,
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _selectedIndex = 0; // Reset selected record on new search
          });
        },
        decoration: InputDecoration(
          hintText: "Tìm hồ sơ bệnh nhân theo tên, email, triệu chứng hoặc chẩn đoán...",
          prefixIcon: const Icon(Icons.search, color: kSecondaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedIndex = 0;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPatientListDropdown(List<Map<String, dynamic>> filtered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: kSecondaryColor),
          const SizedBox(width: 12),
          const Text("Chọn hồ sơ bệnh nhân: ", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedIndex,
                isExpanded: true,
                items: List.generate(filtered.length, (idx) {
                  final rec = filtered[idx];
                  final name = rec['patientName'] ?? 'Không rõ';
                  final diag = rec['diagnosis'] ?? 'Chưa chẩn đoán';
                  final date = rec['visitDate'] ?? rec['examinationDate'] ?? 'N/A';
                  // format date nicely if it's parsed
                  String cleanDate = date;
                  final parsedDate = MedicalRecordService.tryParseDateTime(date);
                  if (parsedDate != null) {
                    cleanDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                  }

                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Text("$name - $diag ($cleanDate)"),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedIndex = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSummary(Map<String, dynamic> record) {
    final name = record['patientName'] ?? 'Chưa rõ';
    final age = record['age'] ?? 'N/A';
    final gender = record['gender'] ?? 'N/A';
    final email = record['email'] ?? 'Không có email';
    final status = record['status'] ?? 'pending';

    String initials = "NA";
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length > 1) {
        initials = (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      } else {
        initials = name.substring(0, (name.length > 2 ? 2 : name.length)).toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kSecondaryColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    Text("Tuổi: $age"),
                    Text("Giới tính: $gender"),
                    Text("Email: $email"),
                  ],
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              status == 'completed' ? 'Hoàn thành' : 'Đang điều trị',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: status == 'completed' ? Colors.teal : Colors.orange,
              ),
            ),
            backgroundColor: status == 'completed'
                ? Colors.teal.withOpacity(0.12)
                : Colors.orange.withOpacity(0.12),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: _cardDecoration(),
      child: const TabBar(
        isScrollable: true,
        labelColor: kPrimaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: kPrimaryColor,
        tabs: [
          Tab(text: "Thông tin hành chính"),
          Tab(text: "Lịch sử khám bệnh"),
          Tab(text: "Chỉ số cận lâm sàng"),
          Tab(text: "Đơn thuốc & Điều trị"),
          Tab(text: "Hồ sơ Blockchain/Tài liệu"),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> record) {
    final email = record['email'] ?? 'Không có email';
    final age = record['age'] ?? 'Chưa rõ';
    final gender = record['gender'] ?? 'N/A';
    final bmi = record['bmi'] ?? 'N/A';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _infoCard("CCCD/CMND", "Đã xác minh"),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard("Nghề nghiệp", "Chưa cập nhật"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoCard("Chỉ số BMI", bmi),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard("Giới tính", gender),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoCard("Tuổi bệnh nhân", "$age tuổi"),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard("Tình trạng", record['status'] ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoCard("Email liên hệ", email),
            const SizedBox(height: 16),
            _infoCard("Tiền sử bệnh án", record['symptoms'] ?? 'Không ghi nhận'),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitHistory(List<Map<String, dynamic>> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Ngày khám", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Triệu chứng", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Chẩn đoán", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: history.map((e) {
              final date = e['visitDate'] ?? e['examinationDate'] ?? 'N/A';
              String cleanDate = date;
              final parsedDate = MedicalRecordService.tryParseDateTime(date);
              if (parsedDate != null) {
                cleanDate = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
              }

              return DataRow(
                cells: [
                  DataCell(Text(cleanDate)),
                  DataCell(Text(e['symptoms'] ?? '')),
                  DataCell(Text(e['diagnosis'] ?? '')),
                  DataCell(Text(e['status'] == 'completed' ? 'Đã khám xong' : 'Đang khám')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLabResults(Map<String, dynamic> record) {
    final urea = record['urea'] ?? '';
    final creatinine = record['creatinine'] ?? '';
    final hba1c = record['hba1c'] ?? '';
    final cholesterol = record['cholesterol'] ?? '';
    final triglycerides = record['triglycerides'] ?? '';
    final hdl = record['hdl'] ?? '';
    final ldl = record['ldl'] ?? '';
    final bmi = record['bmi'] ?? '';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kết quả xét nghiệm cận lâm sàng:",
              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildLabMetricRow("HbA1c (Đường huyết trung bình)", hba1c, "4.0 - 5.6 %", "%"),
            _buildLabMetricRow("Cholesterol toàn phần", cholesterol, "< 5.2 mmol/L", "mmol/L"),
            _buildLabMetricRow("Triglycerides", triglycerides, "< 1.7 mmol/L", "mmol/L"),
            _buildLabMetricRow("Urea máu", urea, "2.5 - 7.5 mmol/L", "mmol/L"),
            _buildLabMetricRow("Creatinine máu", creatinine, "53 - 115 µmol/L", "µmol/L"),
            _buildLabMetricRow("HDL Cholesterol (Tốt)", hdl, "> 0.9 mmol/L", "mmol/L"),
            _buildLabMetricRow("LDL Cholesterol (Xấu)", ldl, "< 3.4 mmol/L", "mmol/L"),
            _buildLabMetricRow("Chỉ số khối cơ thể (BMI)", bmi, "18.5 - 24.9", ""),
          ],
        ),
      ),
    );
  }

  Widget _buildLabMetricRow(String label, dynamic value, String normalRange, String unit) {
    final valStr = value?.toString() ?? '';
    final hasValue = valStr.isNotEmpty && valStr != 'null';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? "$valStr $unit" : "Chưa làm xét nghiệm",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasValue ? Colors.black87 : Colors.grey.shade400,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "CSBT: $normalRange",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptions(Map<String, dynamic> record) {
    final treatment = record['treatment']?.toString() ?? '';
    final hasTreatment = treatment.isNotEmpty && treatment != 'null';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication, color: kSecondaryColor),
              SizedBox(width: 8),
              Text(
                "Đơn thuốc & Phác đồ điều trị:",
                style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  hasTreatment ? treatment : "Không có thông tin chỉ định đơn thuốc.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: hasTreatment ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(Map<String, dynamic> record) {
    final tx = record['blockchainTx']?.toString() ?? '';
    final ipfs = record['ipfsHash']?.toString() ?? '';
    final pdfUrl = record['pdfUrl']?.toString() ?? '';

    final hasBlockchain = tx.isNotEmpty && tx != 'null';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Thông Tin Xác Minh Blockchain:",
                style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasBlockchain) ...[
            _buildVerifyRow("Mã giao dịch (Tx):", tx),
            const Divider(),
            _buildVerifyRow("Mã lưu trữ IPFS:", ipfs),
            const Divider(),
            _buildVerifyRow("Liên kết PDF bệnh án:", pdfUrl),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Bệnh án được bảo mật & Neo trên Blockchain thành công",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.gpp_maybe, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "Hồ sơ này chưa được đẩy lên Blockchain",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hồ sơ bệnh án điện tử cần được bác sĩ xác nhận trước khi neo.",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildVerifyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ],
    );
  }
}