import 'package:flutter/material.dart';
import '../../widgets/dotor/send_request_dialog.dart'; 
import '../../services/api_verificationBlockchain.dart'; 
import '../../services/api_medicalRecordBlockchain.dart'; 
import 'dart:convert';
import '../../models/access_request_model.dart';
import 'dart:io';
import '../../services/api_access_request.dart';

// Hệ màu Light Mode thống nhất
const Color _kBgLight = Color(0xFFF8FAFC);
const Color _kCardLight = Color(0xFFFFFFFF);
const Color _kPrimaryBlue = Color(0xFF1E40AF);
const Color _kAccentBlue = Color(0xFF3B82F6);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextGray = Color(0xFF64748B);
const Color _kGreenSuccess = Color(0xFF059669);
const Color _kRedDanger = Color(0xFFDC2626);
const Color _kWarningYellow = Color(0xFFD97706);

class VerifyIntegritySection extends StatefulWidget {
  final Map<String, dynamic>? recordData;
  const VerifyIntegritySection({super.key, this.recordData});

  @override
  State<VerifyIntegritySection> createState() => _VerifyIntegritySectionState();
}

class _VerifyIntegritySectionState extends State<VerifyIntegritySection> {
  final TextEditingController _verifyController = TextEditingController();
  final BlockchainApiService _apiService = BlockchainApiService();
  
  int _currentSubTab = 0; 
  bool _isLoading = false;
  bool _isDownloadingPdf = false;
  
  // Kết quả trả về từ API thật
  VerificationResult? _verificationResult;
  bool _hasError = false;

  // Mảng lưu danh sách dữ liệu thực tế dạng Model nhận từ API
  List<AccessRequestModel> _sentRequests = [];
  final AccessRequestApiService _requestApiService = AccessRequestApiService();
  bool _isFetchingRequests = false;

  @override
  void initState() {
    super.initState();
    print("========= DATALOG TỪ TRANG TRƯỚC TRUYỀN SANG =========");
    if (widget.recordData != null) {
      print(jsonEncode(widget.recordData)); 
    } else {
      print("⚠️ CẢNH BÁO: Không nhận được bất kỳ dữ liệu recordData nào!");
    }
    print("======================================================");
    
    if (widget.recordData != null && widget.recordData?['_id'] != null) {
      _verifyController.text = widget.recordData?['_id'];
    }
    _loadRequestsFromServer();
  }

  // Hàm kéo lịch sử yêu cầu từ Server MongoDB về
  Future<void> _loadRequestsFromServer() async {
  final String? requestedRecordId = widget.recordData?['_id']?.toString();
  
  if (requestedRecordId == null || requestedRecordId.isEmpty) {
    print("⚠️ Không tìm thấy ID hồ sơ trong dữ liệu truyền sang!");
    return;
  }
  setState(() { 
    _isFetchingRequests = true; 
  });
  try {
    final List<AccessRequestModel> serverData = await _requestApiService.getSentRequestsHistory(requestedRecordId);
    setState(() {
      _sentRequests = serverData;
    });
  } catch (e) {
    print("❌ Lỗi khi tải lịch sử yêu cầu từ server: $e");
  } finally {
    setState(() {
      _isFetchingRequests = false;
    });
  }
}
  // Hàm xử lý xem/tải tệp tin PDF bảo mật chính xác quyền truy cập
  Future<void> _handleViewPdfReal() async {
    final String currentRecordId = widget.recordData?['_id']?.toString() ?? _verifyController.text.trim();
    if (currentRecordId.isEmpty) return;

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final File? pdfFile = await MedicalRecordBlockchainService.downloadSecurePdf(currentRecordId);
      
      if (pdfFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tải file hồ sơ gốc thành công! Đang mở..."), backgroundColor: _kGreenSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_person, color: _kRedDanger, size: 24),
                SizedBox(width: 8),
                Text("Từ chối truy cập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              "Bạn chưa được cấp quyền xem tài liệu gốc của hồ sơ này.\n\nChi tiết hệ thống: ${e.toString().replaceAll("Exception: ", "")}",
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy bỏ", style: TextStyle(color: _kTextGray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kAccentBlue, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx); 
                  _showNewRequestDialog(); 
                },
                child: const Text("Gửi yêu cầu xin quyền"),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  // Hàm kích hoạt gọi API xác minh toàn vẹn mật mã chuỗi khối
  void _handleVerifyReal() async {
    final mongoId = _verifyController.text.trim();
    if (mongoId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _verificationResult = null;
      _hasError = false;
    });

    final result = await _apiService.verifyRecordIntegrity(mongoId);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _verificationResult = result;
        _hasError = false;
      } else {
        _verificationResult = null;
        _hasError = true;
      }
    });
  }

  void _showNewRequestDialog() {

    final String currentRecordId = widget.recordData?['_id']?.toString() ?? "";
    final String currentPatientId = widget.recordData?['patient']?['_id']?.toString() ?? widget.recordData?['patientId']?.toString() ?? "";
    final String currentPatientName = widget.recordData?['patient']?['fullName'] ?? widget.recordData?['patientName'] ?? "Bệnh nhân hệ thống";
    final String currentDoctorId = widget.recordData?['doctorId']?.toString() ?? "";
    
    showDialog(
      context: context,
      builder: (context) => SendRequestDialog(
        recordId: currentRecordId,
        patientId: currentPatientId,    
        patientName: currentPatientName,
        onSubmit: (patientId, reason) {
          // Khi gửi yêu cầu thành công, chèn tạm một Model hợp lệ vào đầu mảng để hiển thị lập tức (Optimistic UI)
          setState(() {
            _sentRequests.insert(0, AccessRequestModel(
              id: "REQ-${DateTime.now().millisecondsSinceEpoch}",
              requestId: "REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
              patientId: currentPatientId,
              patientName: currentPatientName,
              doctorId: currentDoctorId,
              reason: reason,
              requestedRecordId: currentRecordId,
              status: "pending",
              time: "Vừa xong",
              createdAt: DateTime.now(),
            ));
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi yêu cầu xác thực thành công!'),
              backgroundColor: _kGreenSuccess,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSubTabButton(0, "Xác minh toàn vẹn", Icons.verified_user_outlined),
                const SizedBox(width: 8),
                _buildSubTabButton(1, "Yêu cầu xem hồ sơ", Icons.lock_outline),
              ],
            ),
            const SizedBox(height: 20),
            _currentSubTab == 0 ? _buildVerifyTabContent() : _buildRequestTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isSelected = _currentSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSubTab = index;
        });
       
        if (index == 1) {
          _loadRequestsFromServer();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kAccentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _kAccentBlue : Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : _kTextGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : _kTextGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyTabContent() {
    final String pName = widget.recordData?['patient']?['fullName'] ?? widget.recordData?['patientName'] ?? "Chưa rõ";
    final String pId = widget.recordData?['_id'] ?? "Chưa rõ";
    final String pSymptoms = widget.recordData?['symptoms'] ?? "Chưa rõ";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.shade200.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text("#", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kAccentBlue)),
                  SizedBox(width: 8),
                  Text("Kiểm tra toàn vẹn mật mã hồ sơ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Hệ thống sẽ đối chiếu mã băm SHA-256 từ tệp PDF gốc lưu tại mạng IPFS phi tập trung với dấu vết bảo mật đóng băng trên Smart Contract.",
                style: TextStyle(fontSize: 13, color: _kTextGray, height: 1.3),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _verifyController,
                      style: const TextStyle(fontSize: 14, color: _kTextDark, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: "Nhập mã id hồ sơ bệnh án để quét...",
                        hintStyle: TextStyle(color: _kTextGray.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: _kBgLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAccentBlue)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleVerifyReal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.shield_outlined, size: 16),
                    label: const Text("Xác minh", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              const Text("Bệnh nhân đang chọn (Bấm để quét nhanh):", style: TextStyle(fontSize: 12, color: _kTextGray, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              _buildPatientQuickTag(pName, pId, pSymptoms),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        if (_verificationResult != null)
          _buildAuditResultCard(_verificationResult!)
        else if (_hasError)
          _buildErrorCard(),
      ],
    );
  }

  Widget _buildPatientQuickTag(String name, String id, String symptoms) {
    return GestureDetector(
      onTap: () {
        _verifyController.text = id;
        _handleVerifyReal();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPrimaryBlue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimaryBlue.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: _kPrimaryBlue),
                const SizedBox(width: 6),
                Text(name, style: const TextStyle(fontSize: 13, color: _kPrimaryBlue, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text("Nhấn để quét ⚡", style: TextStyle(fontSize: 11, color: _kAccentBlue, fontStyle: FontStyle.italic)),
              ],
            ),
            const Divider(height: 12, color: Color(0xFFE2E8F0)),
            Text("Mã hồ sơ (id): $id", style: const TextStyle(fontSize: 11, color: _kTextDark, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text("Triệu chứng lâm sàng: $symptoms", style: const TextStyle(fontSize: 12, color: _kTextGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditResultCard(VerificationResult result) {
    final String rId = widget.recordData?['_id'] ?? "N/A";
    final String rDiagnosis = widget.recordData?['diagnosis'] ?? "Khám lâm sàng";
    final String rNetwork = widget.recordData?['blockchainNetwork'] ?? "Sepolia Testnet";
    final String rCid = widget.recordData?['ipfsHash'] ?? "N/A";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isVerifiedSuccess ? _kGreenSuccess.withOpacity(0.08) : _kRedDanger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: result.isVerifiedSuccess ? _kGreenSuccess.withOpacity(0.3) : _kRedDanger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  result.isVerifiedSuccess ? Icons.verified_outlined : Icons.gpp_bad_outlined, 
                  color: result.isVerifiedSuccess ? _kGreenSuccess : _kRedDanger, 
                  size: 24
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isVerifiedSuccess ? "Hồ sơ toàn vẹn — Khớp mật mã" : "Cảnh báo toàn vẹn dữ liệu", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: result.isVerifiedSuccess ? _kGreenSuccess : _kRedDanger)
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.isVerifiedSuccess 
                            ? "Mã Hash trên Blockchain khớp hoàn toàn 100% với tệp tin PDF lưu trên IPFS."
                            : "Phát hiện sự sai lệch! Tập tin PDF đã bị tác động sửa đổi cấu trúc dữ liệu.", 
                        style: TextStyle(fontSize: 12, color: (result.isVerifiedSuccess ? _kGreenSuccess : _kRedDanger).withOpacity(0.9))
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloadingPdf ? null : _handleViewPdfReal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: _isDownloadingPdf
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                _isDownloadingPdf ? "Đang giải mã và tải tệp tin..." : "Xem Hồ Sơ Bản Gốc Hệ Thống (PDF)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetaItem("Mã hồ sơ (_id)", rId, isHighlight: true)),
              Expanded(child: _buildMetaItem("Chẩn đoán DB", rDiagnosis)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetaItem("Mạng chuỗi khối", rNetwork.toUpperCase())),
              Expanded(child: _buildMetaItem("Vị trí khối (Block)", result.blockNumber != null ? "#${result.blockNumber}" : "Đang cập nhật", isHighlight: true)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildHashItem("HASH TRÊN SMART CONTRACT (ON-CHAIN)", result.blockchainHash, _kGreenSuccess),
          const SizedBox(height: 14),
          _buildHashItem("HASH TÍNH ĐƯỢC TỪ TỆP HIỆN TẠI (COMPUTED)", result.computedHash, result.isVerifiedSuccess ? _kGreenSuccess : _kRedDanger),
          const SizedBox(height: 14),
          _buildHashItem("BLOCKCHAIN TRANSACTION HASH (TX)", widget.recordData?['blockchainTx'] ?? "N/A", _kAccentBlue),
          const SizedBox(height: 14),
          _buildHashItem("IPFS CONTENT IDENTIFIER (CID)", rCid, _kTextGray),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: _kTextGray, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isHighlight ? _kAccentBlue : _kTextDark)),
      ],
    );
  }

  Widget _buildHashItem(String title, String hash, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kTextGray, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _kBgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200, width: 0.5)),
          child: SelectableText(hash, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color, height: 1.2, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kCardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kRedDanger.withOpacity(0.2))),
      child: Column(
        children: [
          const Icon(Icons.gpp_bad_outlined, color: _kRedDanger, size: 40),
          const SizedBox(height: 8),
          const Text("Xác minh thất bại", style: TextStyle(fontWeight: FontWeight.bold, color: _kTextDark)),
          const SizedBox(height: 4),
          const Text(
            "Không thể truy xuất mã bệnh án hoặc tệp chưa được lưu trữ chính xác trên chuỗi khối Sepolia công khai.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _kTextGray),
          ),
        ],
      ),
    );
  }

  // --- HIỂN THỊ DANH SÁCH THEO MODEL TĨNH TỪ ĐƯỜNG TRUYỀN API THỰC TẾ ---
  Widget _buildRequestTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Lịch sử yêu cầu đã gửi tới bệnh nhân", style: TextStyle(fontSize: 13, color: _kTextGray)),
            ElevatedButton.icon(
              onPressed: _showNewRequestDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text("Gửi yêu cầu mới", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🚀 Đã sửa: Kiểm tra nếu trạng thái đang kéo API từ Node.js thì hiện hiệu ứng xoay tròn
        _isFetchingRequests
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: _kAccentBlue),
                ),
              )
            : _sentRequests.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: _kCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: _kTextGray),
                        SizedBox(height: 12),
                        Text(
                          "Chưa có yêu cầu truy cập nào được khởi tạo.",
                          style: TextStyle(fontSize: 14, color: _kTextDark, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Nhấn nút 'Gửi yêu cầu mới' ở góc trên để xin quyền.",
                          style: TextStyle(fontSize: 12, color: _kTextGray),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sentRequests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      // 🚀 Đã cấu hình: req lúc này là 1 instance an toàn của AccessRequestModel
                      final req = _sentRequests[index];
                      
                      final String status = req.status.toLowerCase();
                      final String displayTime = req.time?.isNotEmpty == true 
                          ? req.time! 
                          : "Vừa xong";

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kCardLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(req.requestId, style: const TextStyle(fontSize: 12, color: _kTextGray, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (status == 'completed' || status == 'approved') 
                                            ? _kGreenSuccess.withOpacity(0.08) 
                                            : (status == 'rejected')
                                                ? _kRedDanger.withOpacity(0.08)
                                                : _kWarningYellow.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (status == 'completed' || status == 'approved') 
                                              ? _kGreenSuccess.withOpacity(0.3) 
                                              : (status == 'rejected')
                                                  ? _kRedDanger.withOpacity(0.3)
                                                  : _kWarningYellow.withOpacity(0.3)
                                        ),
                                      ),
                                      child: Text(
                                        (status == 'completed' || status == 'approved') 
                                            ? "Đã phê duyệt" 
                                            : (status == 'rejected') 
                                                ? "Từ chối" 
                                                : "Chờ xác nhận", 
                                        style: TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold, 
                                          color: (status == 'completed' || status == 'approved') 
                                              ? _kGreenSuccess 
                                              : (status == 'rejected')
                                                  ? _kRedDanger
                                                  : _kWarningYellow
                                        )
                                      ),
                                    ),
                                  ],
                                ),
                                Text(displayTime, style: const TextStyle(fontSize: 12, color: _kTextGray)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text("Bệnh nhân: ${req.patientName}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kTextDark)),
                            const SizedBox(height: 4),
                            Text("Mã định danh (ID): ${req.patientId}", style: const TextStyle(fontSize: 11, color: _kTextGray, fontFamily: 'monospace')),
                            const SizedBox(height: 8),
                            Text(req.reason, style: const TextStyle(fontSize: 13, color: _kTextGray, height: 1.4)),
                          ],
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}