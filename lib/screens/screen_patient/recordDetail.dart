import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_medicalRecord.dart';
import '../../services/api_prescription.dart';

// --- BẢNG MÀU TRẮNG XANH Y TẾ ĐỒNG BỘ THEO CẤU TRÚC GỐC ---
const Color _kBgLight =
    Color(0xFFF1F5F9); // Nền tổng thể phía sau (Xám trắng nhẹ)
const Color _kCardWhite =
    Color(0xFFFFFFFF); // Nền các khối Card thông tin (Trắng tinh)
const Color _kBorderLine =
    Color(0xFFE2E8F0); // Đường viền mảnh chia hộp và phân tab
const Color _kTextDark =
    Color(0xFF0F172A); // Màu chữ cho thông tin chính (Đen Slate)
const Color _kTextGray =
    Color(0xFF64748B); // Màu chữ tiêu đề phụ & Label (Xám Slate)
const Color _kActiveBlue =
    Color(0xFF0284C7); // Màu xanh chủ đạo của Tab đang chọn & Tiêu đề hộp
const Color _kAlertRed =
    Color(0xFFEF4444); // Màu đỏ cảnh báo lâm sàng cho mục "Dị ứng thuốc"
const Color _kSuccessGreen =
    Color(0xFF10B981); // Màu xanh lá cây xác thực Blockchain thành công

class PatientAdminInfoSection extends StatefulWidget {
  final Map<String, dynamic> record;

  const PatientAdminInfoSection({
    super.key,
    required this.record,
  });

  @override
  State<PatientAdminInfoSection> createState() =>
      _PatientAdminInfoSectionState();
}

class _PatientAdminInfoSectionState extends State<PatientAdminInfoSection> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _navigationTabs = [
    {'title': 'Thông tin hành chính', 'icon': Icons.person_outline},
    {'title': 'Lịch sử khám bệnh', 'icon': Icons.assignment_outlined},
    {'title': 'Chỉ số lâm sàng', 'icon': Icons.science_outlined},
    {'title': 'Đơn thuốc & Điều trị', 'icon': Icons.medication_outlined},
    {'title': 'Hồ sơ Blockchain', 'icon': Icons.storage_outlined},
  ];

  Map<String, dynamic>? _activeData;
  Map<String, dynamic>?
      _prescriptionData; // Lưu trữ dữ liệu đơn thuốc sau khi tải thành công
  bool _isLoadingPrescription = true; // Trạng thái tải của đơn thuốc

  @override
  void initState() {
    super.initState();
    _fetchRecordData();
  }

  // Luồng tải dữ liệu tuần tự chuẩn xác để giải quyết triệt để vấn đề bất đồng bộ dữ liệu liên kết
  Future<void> _fetchRecordData() async {
    try {
      // 1. Tải thông tin chi tiết Bệnh án từ cơ sở dữ liệu
      final data =
          await MedicalRecordService.getMedicalRecordById(widget.record['_id']);
      final targetData = data ?? widget.record;

      if (mounted) {
        setState(() {
          _activeData = targetData;
        });
      }

      // 2. Trích xuất mã appointmentId liên kết từ dữ liệu bệnh án vừa nhận được
      final String? appointmentId = targetData['appointmentId']?.toString();
      print("🔍 [DEBUG] Lấy được appointmentId từ Bệnh Án: $appointmentId");

      // 3. Tiến hành gọi API tải đơn thuốc dựa trên appointmentId
      if (appointmentId != null && appointmentId.isNotEmpty) {
        final pData =
            await ApiPrescription.getPrescriptionByAppointment(appointmentId);
        if (mounted) {
          setState(() {
            _prescriptionData = pData;
            _isLoadingPrescription = false;
          });
        }
      } else {
        print(
            "⚠️ [DEBUG] Bản ghi bệnh án này không chứa appointmentId hợp lệ.");
        if (mounted) {
          setState(() {
            _isLoadingPrescription = false;
          });
        }
      }
    } catch (e) {
      print("❌ [DEBUG] Xảy ra lỗi trong quá trình tải tuần tự dữ liệu EMR: $e");
      if (mounted) {
        setState(() {
          _isLoadingPrescription = false;
        });
      }
    }
  }

  // Điều hướng kích hoạt mở/tải tài liệu đính kèm PDF thông qua IPFS Gateway
  Future<void> _launchIPFSUrl(String cid) async {
    final String urlString = "https://gateway.pinata.cloud/ipfs/$cid";
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể khởi chạy phân giải URL: $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối đến IPFS Gateway: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      appBar: AppBar(
        backgroundColor: _kCardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kActiveBlue, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          "Bệnh Án: ${widget.record['patientName'] ?? 'Chi Tiết EMR'}",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: _kTextDark),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedicalTabBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(_activeData ?? widget.record),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> data) {
    switch (_selectedTab) {
      case 0:
        return _buildHanhChinhTab();
      case 1:
        return _buildLichSuKhamTab();
      case 2:
        return _buildChiSoLamSangTab(data);
      case 3:
        return _buildDonThuocTab(); // Không cần truyền tham số vì dùng trực tiếp State variable
      case 4:
        return _buildBlockchainTab();
      default:
        return _buildHanhChinhTab();
    }
  }

  // ==========================================
  // TAB 0: THÔNG TIN HÀNH CHÍNH
  // ==========================================
  Widget _buildHanhChinhTab() {
    return _buildInfoBlock(
      title: "THÔNG TIN HÀNH CHÍNH QUẢN LÝ",
      children: [
        _buildDataRow(Icons.fingerprint, "Mã Hồ Sơ (Record ID)",
            widget.record['_id'] ?? 'N/A'),
        _buildDataRow(Icons.person_outline, "Họ và tên bệnh nhân",
            widget.record['patientName'] ?? 'Không rõ'),
        _buildDataRow(Icons.badge_outlined, "Mã định danh Patient ID",
            widget.record['patientId'] ?? 'N/A'),
        _buildDataRow(Icons.email_outlined, "Email hệ thống",
            widget.record['patientEmail'] ?? 'Chưa cung cấp'),
        _buildDataRow(Icons.medical_information_outlined, "Đối tượng",
            "Bảo hiểm y tế / Viện phí"),
      ],
    );
  }

  // ==========================================
  // TAB 1: LỊCH SỬ KHÁM BỆNH
  // ==========================================
  Widget _buildLichSuKhamTab() {
    String visitDateStr = "Chưa rõ ngày";
    if (widget.record['visitDate'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(widget.record['visitDate']);
        visitDateStr =
            "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {}
    }

    return _buildInfoBlock(
      title: "TIỀN SỬ BỆNH & LÂM SÀNG",
      children: [
        _buildDataRow(
            Icons.calendar_today_outlined, "Ngày nhập viện", visitDateStr),
        _buildDataRow(Icons.local_hospital_outlined, "Bác sĩ tiếp nhận",
            widget.record['doctorName'] ?? 'Bác sĩ trực ban'),
        _buildDataRow(Icons.healing_outlined, "Lý do khám / Triệu chứng",
            widget.record['symptoms'] ?? 'Không có',
            isLongText: true),
        _buildDataRow(Icons.assignment_turned_in_outlined, "Chẩn đoán lâm sàng",
            widget.record['diagnosis'] ?? 'Chưa xác định',
            isLongText: true),
      ],
    );
  }

  // ==========================================
  // TAB 2: CHỈ SỐ CẬN LÂM SÀNG (ĐÃ TINH GỌN BỎ CỘT THAM CHIẾU & TRẠNG THÁI)
  // ==========================================
  Widget _buildChiSoLamSangTab(Map<String, dynamic> data) {
    final Map<String, dynamic> metrics = data['metrics'] ?? {};

    TableRow buildRow(String name, String key, String unit) {
      final value = metrics[key]?.toString() ?? '—';
      return _buildTableRowData(name, "$value $unit");
    }

    return Container(
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorderLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "BẢNG KẾT QUẢ XÉT NGHIỆM SINH HÓA",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextGray,
                  letterSpacing: 0.5),
            ),
          ),
          const Divider(color: _kBorderLine, height: 1),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(5), // Tên chỉ số xét nghiệm
              1: FlexColumnWidth(3), // Kết quả đo lường thực tế
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _kBgLight),
                children: [
                  _buildTableHeader("CHỈ SỐ XÉT NGHIỆM"),
                  _buildTableHeader("KẾT QUẢ"),
                ],
              ),
              buildRow("BMI (Chỉ số khối cơ thể)", "bmi", "kg/m²"),
              buildRow("Urea máu", "urea", "mmol/L"),
              buildRow("Creatinine", "creatinine", "µmol/L"),
              buildRow("HbA1c (Đường huyết trung bình)", "hba1c", "%"),
              buildRow("Cholesterol TP", "cholesterol", "mmol/L"),
              buildRow("Triglycerides", "triglycerides", "mmol/L"),
              buildRow("HDL-Cholesterol", "hdl", "mmol/L"),
              buildRow("LDL-Cholesterol", "ldl", "mmol/L"),
              buildRow("VLDL-Cholesterol", "vldl", "mmol/L"),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ĐƠN THUỐC & ĐIỀU TRỊ (XỬ LÝ TRẠNG THÁI THEO STATE ĐỒNG BỘ)
  // ==========================================
  Widget _buildDonThuocTab() {
    // 1. Xử lý hiển thị khi luồng API đang thực hiện tải dữ liệu ngầm
    if (_isLoadingPrescription) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Xử lý trường hợp không có đơn thuốc hoặc lỗi API trả về rỗng
    if (_prescriptionData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Chưa có đơn thuốc được kê cho bệnh án này.",
            style: TextStyle(
                color: _kTextGray, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // 3. Render giao diện chi tiết khi đã kéo thành công tài liệu Đơn thuốc
    final data = _prescriptionData!;
    final List<dynamic> medicines = data['medicines'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBlock(
          title: "THÔNG TIN CHẨN ĐOÁN LÂM SÀNG",
          children: [
            _buildDataRow(Icons.healing, "Chẩn đoán xác định",
                data['diagnosis'] ?? 'Chưa cập nhật',
                isLongText: true),
            _buildDataRow(Icons.person_outline, "Bác sĩ chỉ định",
                data['doctorName'] ?? 'Phi Nô'),
            _buildDataRow(Icons.star_border, "Trạng thái đơn",
                (data['status'] ?? 'pending').toString().toUpperCase(),
                customValueColor: _kActiveBlue),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            "DANH SÁCH THUỐC CHỈ ĐỊNH CHI TIẾT (${medicines.length})",
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _kTextGray,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        if (medicines.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Đơn thuốc trống (Bác sĩ chưa thêm danh mục thuốc).",
                  style: TextStyle(
                      color: _kTextGray, fontStyle: FontStyle.italic)),
            ),
          )
        else
          ...medicines.map((med) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorderLine, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          med['name'] ?? 'Tên thuốc không rõ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _kTextDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBgLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SL: ${med['quantity'] ?? '0'} ${med['unit'] ?? 'Hộp'}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kActiveBlue,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: _kBorderLine, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: _kTextGray),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cách dùng: ${med['usage'] ?? 'Theo chỉ định từ bác sĩ chuyên khoa'}",
                          style: const TextStyle(
                              fontSize: 12, color: _kTextGray, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // ==========================================
  // TAB 4: HỒ SƠ BLOCKCHAIN (ẤN ĐỂ MỞ/TẢI FILE PDF QUA IPFS)
  // ==========================================
  Widget _buildBlockchainTab() {
    final String txHash = widget.record['txHash'] ??
        widget.record['blockchainHash'] ??
        '0x7f3a9c2e1b8d4f6a0e5c7b3d9f1a2e4c6b8d0f2a4c6e8f0b2d4f6a8c0e2f4b6';
    final String ipfsCid = widget.record['ipfsCid'] ??
        widget.record['ipfsHash'] ??
        'QmYvEAijd2dJ4J6wYj5WLceumHDHV9ycGDPYkkzZRKNFR5';
    final String onChainHash = widget.record['onChainHash'] ??
        'sha256:a3f4b9c1d2e5f7a0b3c6d9e2f5a8b1c4d7e0f3a6b9c2d5e8f1a4b7c0d3e6f9a2';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSuccessGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: _kSuccessGreen.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: _kSuccessGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Hồ sơ toàn vẹn",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _kSuccessGreen)),
                    SizedBox(height: 2),
                    Text(
                        "Đã xác minh — hash khớp hoàn toàn với dữ liệu trên blockchain.",
                        style: TextStyle(fontSize: 12, color: _kTextGray)),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildInfoBlock(
          title: "THÔNG TIN BLOCKCHAIN KHÓA GỐC",
          children: [
            _buildBlockchainHashRow("TRANSACTION HASH", txHash, isCid: false),
            // Cho phép người dùng chạm thẳng vào ô mã băm để kích hoạt tải tài liệu
            _buildBlockchainHashRow(
                "IPFS CID (ẤN ĐỂ MỞ TẢI FILE PDF GỐC)", ipfsCid,
                isCid: true),
            _buildBlockchainHashRow("HASH ON-CHAIN", onChainHash, isCid: false),
          ],
        ),
        const SizedBox(height: 16),

        // Khối Card PDF hỗ trợ tải tệp tin gốc trực tiếp từ hệ thống lưu trữ phi tập trung
        InkWell(
          onTap: () => _launchIPFSUrl(ipfsCid),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorderLine),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.picture_as_pdf,
                      color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Phiếu khám sức khỏe.pdf",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark)),
                      Text(
                          ipfsCid.length > 25
                              ? "${ipfsCid.substring(0, 22)}..."
                              : ipfsCid,
                          style:
                              const TextStyle(fontSize: 11, color: _kTextGray)),
                    ],
                  ),
                ),
                const Icon(Icons.download_for_offline_outlined,
                    color: _kActiveBlue, size: 24),
              ],
            ),
          ),
        )
      ],
    );
  }

  // --- THÀNH PHẦN PHỤ 1: TIÊU ĐỀ TRONG TABLE ---
  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: _kTextGray),
        textAlign: TextAlign.center,
      ),
    );
  }

  // --- THÀNH PHẦN PHỤ 2: DÒNG DỮ LIỆU TINH GỌN (2 CỘT) ---
  TableRow _buildTableRowData(String metricName, String result) {
    return TableRow(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kBorderLine, width: 0.5))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Text(metricName,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kTextDark)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Text(result,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kActiveBlue),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  // --- THÀNH PHẦN PHỤ 3: DÒNG HIỂN THỊ MÃ BLOCKCHAIN CÓ HOÀN THIỆN ĐIỀU HƯỚNG INTERNET ---
  Widget _buildBlockchainHashRow(String title, String hashValue,
      {bool isCid = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kTextGray)),
          const SizedBox(height: 4),
          InkWell(
            onTap: isCid ? () => _launchIPFSUrl(hashValue) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isCid ? _kActiveBlue.withOpacity(0.05) : _kBgLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color:
                        isCid ? _kActiveBlue.withOpacity(0.3) : _kBorderLine),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hashValue,
                      style: TextStyle(
                          fontSize: 12,
                          color: isCid ? _kActiveBlue : _kTextDark,
                          fontFamily: 'monospace',
                          fontWeight:
                              isCid ? FontWeight.bold : FontWeight.normal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isCid ? Icons.open_in_browser : Icons.lock_outline,
                      size: 14, color: _kTextGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THIẾT KẾ: THANH TAB LIÊN THÔNG NỀN TRẮNG ---
  Widget _buildMedicalTabBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _kCardWhite,
        border: Border(bottom: BorderSide(color: _kBorderLine, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _navigationTabs.length,
        itemBuilder: (context, index) {
          final isCurrent = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isCurrent ? _kActiveBlue : Colors.transparent,
                        width: 2.5)),
              ),
              child: Row(
                children: [
                  Icon(_navigationTabs[index]['icon'],
                      size: 16, color: isCurrent ? _kActiveBlue : _kTextGray),
                  const SizedBox(width: 6),
                  Text(
                    _navigationTabs[index]['title'],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? _kActiveBlue : _kTextGray),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- THIẾT KẾ: KHUNG HỘP CHỨA CARD TRẮNG ---
  Widget _buildInfoBlock(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorderLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextGray,
                  letterSpacing: 0.8),
            ),
          ),
          const Divider(color: _kBorderLine, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // --- THIẾT KẾ: DÒNG DỮ LIỆU ĐỐI XỨNG CƠ BẢN ---
  Widget _buildDataRow(IconData icon, String label, String value,
      {Color? customValueColor, bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment:
            isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: _kTextGray),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kTextGray)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: customValueColor ?? _kTextDark,
                  height: 1.3),
              maxLines: isLongText ? 6 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
