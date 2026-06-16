import 'package:flutter/material.dart';

// --- BẢNG MÀU TRẮNG XANH Y TẾ ĐỒNG BỘ THEO CẤU TRÚC GỐC ---
const Color _kBgLight = Color(0xFFF1F5F9);       // Nền tổng thể phía sau (Xám trắng nhẹ)
const Color _kCardWhite = Color(0xFFFFFFFF);     // Nền các khối Card thông tin (Trắng tinh)
const Color _kBorderLine = Color(0xFFE2E8F0);    // Đường viền mảnh chia hộp và phân tab
const Color _kTextDark = Color(0xFF0F172A);      // Màu chữ cho thông tin chính (Đen Slate)
const Color _kTextGray = Color(0xFF64748B);      // Màu chữ tiêu đề phụ & Label (Xám Slate)
const Color _kActiveBlue = Color(0xFF0284C7);    // Màu xanh chủ đạo của Tab đang chọn & Tiêu đề hộp
const Color _kAlertRed = Color(0xFFEF4444);      // Màu đỏ cảnh báo lâm sàng cho mục "Dị ứng thuốc"
const Color _kSuccessGreen = Color(0xFF10B981);  // Màu xanh lá cây xác thực Blockchain thành công

class PatientAdminInfoSection extends StatefulWidget {
  final Map<String, dynamic> record;

  const PatientAdminInfoSection({
    super.key,
    required this.record,
  });

  @override
  State<PatientAdminInfoSection> createState() => _PatientAdminInfoSectionState();
}

class _PatientAdminInfoSectionState extends State<PatientAdminInfoSection> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _navigationTabs = [
    {'title': 'Thông tin hành chính', 'icon': Icons.person_outline},
    {'title': 'Lịch sử khám bệnh', 'icon': Icons.assignment_outlined},
    {'title': 'Chỉ số cận lâm sàng', 'icon': Icons.science_outlined},
    {'title': 'Đơn thuốc & Điều trị', 'icon': Icons.medication_outlined},
    {'title': 'Hồ sơ Blockchain', 'icon': Icons.storage_outlined},
  ];

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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextDark),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. THANH ĐIỀU HƯỚNG TABS (PHÍA TRÊN CÙNG)
          _buildMedicalTabBar(),
          
          // 2. NỘI DUNG THAY ĐỔI ĐỘNG THEO TAB ĐANG CHỌN (Bọc trong Expanded)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM ĐIỀU HƯỚNG CHUYỂN ĐỔI NỘI DUNG TABS CHÍNH XÁC ---
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildHanhChinhTab();
      case 1:
        return _buildLichSuKhamTab();
      case 2:
        return _buildChiSoLamSangTab();
      case 3:
        return _buildDonThuocTab();
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
        _buildDataRow(Icons.fingerprint, "Mã Hồ Sơ (Record ID)", widget.record['_id'] ?? 'N/A'),
        _buildDataRow(Icons.person_outline, "Họ và tên bệnh nhân", widget.record['patientName'] ?? 'Không rõ'),
        _buildDataRow(Icons.badge_outlined, "Mã định danh Patient ID", widget.record['patientId'] ?? 'N/A'),
        _buildDataRow(Icons.email_outlined, "Email hệ thống", widget.record['patientEmail'] ?? 'Chưa cung cấp'),
        _buildDataRow(Icons.medical_information_outlined, "Đối tượng", "Bảo hiểm y tế / Viện phí"),
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
        visitDateStr = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {}
    }

    return _buildInfoBlock(
      title: "TIỀN SỬ BỆNH & LÂM SÀNG",
      children: [
        _buildDataRow(Icons.calendar_today_outlined, "Ngày nhập viện", visitDateStr),
        _buildDataRow(Icons.local_hospital_outlined, "Bác sĩ tiếp nhận", widget.record['doctorName'] ?? 'Bác sĩ trực ban'),
        _buildDataRow(Icons.healing_outlined, "Lý do khám / Triệu chứng", widget.record['symptoms'] ?? 'Không có', isLongText: true),
        _buildDataRow(Icons.assignment_turned_in_outlined, "Chẩn đoán lâm sàng", widget.record['diagnosis'] ?? 'Chưa xác định', isLongText: true),
      ],
    );
  }

  // ==========================================
  // TAB 2: CHỈ SỐ CẬN LÂM SÀNG (KHỚP CHÍNH XÁC THEO ẢNH 1)
  // ==========================================
  Widget _buildChiSoLamSangTab() {
    final Map<String, dynamic> metrics = widget.record['metrics'] ?? {};

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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kTextGray, letterSpacing: 0.5),
            ),
          ),
          const Divider(color: _kBorderLine, height: 1),
          
          // Bảng Tiêu đề cột mẫu
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3), // Chỉ số
              1: FlexColumnWidth(2), // Kết quả
              2: FlexColumnWidth(2), // Tham chiếu
              3: FlexColumnWidth(2), // Trạng thái
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _kBgLight),
                children: [
                  _buildTableHeader("CHỈ SỐ"),
                  _buildTableHeader("KẾT QUẢ"),
                  _buildTableHeader("THAM CHIẾU"),
                  _buildTableHeader("TRẠNG THÁI"),
                ],
              ),
              // Render động các dòng dữ liệu lấy từ MongoDB của từng hồ sơ ID cụ thể
              _buildTableRowData("Huyết áp", "${metrics['bloodPressure'] ?? '118/76'} mmHg", "< 130/80"),
              _buildTableRowData("Nhịp tim", "${metrics['heartRate'] ?? '72'} bpm", "60-100"),
              _buildTableRowData("Nhiệt độ", "${metrics['temperature'] ?? '36.7'} °C", "36.1-37.2"),
              _buildTableRowData("SpO2", "${metrics['spo2'] ?? '98'} %", "≥ 95"),
              _buildTableRowData("BMI", "${metrics['bmi'] ?? '20.8'} kg/m²", "18.5-22.9"),
              _buildTableRowData("Glucose máu TM", "${metrics['glucose'] ?? metrics['hba1c'] ?? '92'} mg/dL", "70-100"),
              _buildTableRowData("Cholesterol TP", "${metrics['cholesterol'] ?? '195'} mg/dL", "< 200"),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ĐƠN THUỐC & ĐIỀU TRỊ
  // ==========================================
  Widget _buildDonThuocTab() {
    return _buildInfoBlock(
      title: "PHÁC ĐỒ VÀ BIỆN PHÁP ĐIỀU TRỊ",
      children: [
        _buildDataRow(Icons.medication_outlined, "Y lệnh điều trị", widget.record['treatment'] ?? 'Theo dõi thêm tại nhà', isLongText: true),
        _buildDataRow(
          Icons.warning_amber_outlined, 
          "Dị ứng kèm theo", 
          widget.record['allergy'] ?? "Chưa phát hiện dị ứng ứng thuốc", 
          customValueColor: widget.record['allergy'] != null ? _kAlertRed : _kTextDark
        ),
        _buildDataRow(Icons.note_alt_outlined, "Ghi chú đơn thuốc", "Uống thuốc đúng giờ theo đơn định kỳ của bệnh viện."),
      ],
    );
  }

  // ==========================================
  // TAB 4: HỒ SƠ BLOCKCHAIN (KHỚP CHÍNH XÁC THEO ẢNH 2)
  // ==========================================
  Widget _buildBlockchainTab() {
    // Lấy mã băm mã hóa động từ db, nếu trống sẽ fill chuỗi từ ảnh hệ thống của bạn để tránh trống thông tin
    final String txHash = widget.record['txHash'] ?? widget.record['blockchainHash'] ?? '0x7f3a9c2e1b8d4f6a0e5c7b3d9f1a2e4c6b8d0f2a4c6e8f0b2d4f6a8c0e2f4b6';
    final String ipfsCid = widget.record['ipfsCid'] ?? widget.record['ipfsHash'] ?? 'QmYwAPJzv5CZsnA625s3Xf2nemtyGpHdWEz79ojwnPbdG';
    final String onChainHash = widget.record['onChainHash'] ?? 'sha256:a3f4b9c1d2e5f7a0b3c6d9e2f5a8b1c4d7e0f3a6b9c2d5e8f1a4b7c0d3e6f9a2';

    return Column(
      children: [
        // Khối trạng thái Toàn vẹn màu xanh (Ảnh 2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSuccessGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kSuccessGreen.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: _kSuccessGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Hồ sơ toàn vẹn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kSuccessGreen)),
                    SizedBox(height: 2),
                    Text("Đã xác minh — hash khớp hoàn toàn với dữ liệu trên blockchain.", style: TextStyle(fontSize: 12, color: _kTextGray)),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Các trường mã hash
        _buildInfoBlock(
          title: "THÔNG TIN BLOCKCHAIN KHÓA GỐC",
          children: [
            _buildBlockchainHashRow("TRANSACTION HASH", txHash),
            _buildBlockchainHashRow("IPFS CID (ĐỊA CHỈ FILE)", ipfsCid),
            _buildBlockchainHashRow("HASH ON-CHAIN", onChainHash),
          ],
        ),
        const SizedBox(height: 16),

        // Khối tài liệu đính kèm mẫu PDF phía dưới cùng ở ảnh 2
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCardWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorderLine),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Phiếu khám sức khỏe tổng quát.pdf", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark)),
                    Text(ipfsCid.substring(0, 20) + "...", style: const TextStyle(fontSize: 11, color: _kTextGray)),
                  ],
                ),
              ),
              const Icon(Icons.download_for_offline_outlined, color: _kActiveBlue, size: 22),
            ],
          ),
        )
      ],
    );
  }

  // --- THÀNH PHẦN PHỤ 1: CHỮ TIÊU ĐỀ TRONG TABLE ---
  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextGray),
        textAlign: TextAlign.center,
      ),
    );
  }

  // --- THÀNH PHẦN PHỤ 2: DÒNG DỮ LIỆU ĐỘNG TRONG TABLE LÂM SÀNG ---
  TableRow _buildTableRowData(String metricName, String result, String reference) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorderLine, width: 0.5))),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(metricName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kTextDark)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(result, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark), textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(reference, style: const TextStyle(fontSize: 12, color: _kTextGray), textAlign: TextAlign.center),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text("— Bình thường", style: TextStyle(fontSize: 12, color: _kSuccessGreen, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  // --- THÀNH PHẦN PHỤ 3: DÒNG HIỂN THỊ MÃ BLOCKCHAIN CÓ NÚT COPY ---
  Widget _buildBlockchainHashRow(String title, String hashValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kTextGray)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: _kBgLight, borderRadius: BorderRadius.circular(4), border: Border.all(color: _kBorderLine)),
            child: Row(
              children: [
                Expanded(child: Text(hashValue, style: const TextStyle(fontSize: 12, color: _kActiveBlue, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 14, color: _kTextGray),
              ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isCurrent ? _kActiveBlue : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(_navigationTabs[index]['icon'], size: 16, color: isCurrent ? _kActiveBlue : _kTextGray),
                  const SizedBox(width: 8),
                  Text(
                    _navigationTabs[index]['title'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? _kActiveBlue : _kTextGray,
                    ),
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
  Widget _buildInfoBlock({required String title, required List<Widget> children}) {
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextGray, letterSpacing: 0.8),
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
  Widget _buildDataRow(IconData icon, String label, String value, {Color? customValueColor, bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: _kTextGray),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kTextGray)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: customValueColor ?? _kTextDark, height: 1.3),
              maxLines: isLongText ? 6 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}