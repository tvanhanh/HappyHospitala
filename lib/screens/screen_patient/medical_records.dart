import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_medicalRecordBlockchain.dart';
import '../../services/api_access_request.dart'; 
import '../../models/access_request_model.dart';        
import '../../providers/auth_provider.dart';
import 'medical_record_card.dart';
import 'recordDetail.dart'; 
import '../../widgets/dotor/access_approval_dialog.dart';

// --- BẢNG MÀU ĐẶC TRƯNG LIGHT MODE ---
const Color _kBgLight = Color(0xFFF8FAFC);
const Color _kCardLight = Color(0xFFFFFFFF);
const Color _kPrimaryBlue = Color(0xFF1E40AF);
const Color _kAccentBlue = Color(0xFF3B82F6);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextGray = Color(0xFF64748B);
const Color _kGreenSuccess = Color(0xFF059669);
const Color _kRedDanger = Color(0xFFDC2626);

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> {
  final TextEditingController patientIdController = TextEditingController();
  final AccessRequestApiService _requestApiService = AccessRequestApiService();

  List<Map<String, dynamic>> records = [];
  List<AccessRequestModel> receivedRequests = []; 
  
  bool loadingRecords = false;
  bool loadingRequests = false; 
  bool isPatient = false;
  int _selectedTab = 0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadData();
    });
  }

  Future<void> _checkAndLoadData() async {
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
    await _fetchReceivedRequests();
  }

  // API 1: Lấy danh sách bệnh án EMR
  Future<void> _fetchRecords(String patientId) async {
    if (patientId.isEmpty) return;
    setState(() => loadingRecords = true);
    try {
      final results = await MedicalRecordBlockchainService.searchMedicalRecordsByPatientId(patientId);
      setState(() {
        records = List<Map<String, dynamic>>.from(results);
        loadingRecords = false;
      });
    } catch (e) {
      setState(() => loadingRecords = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải bệnh án: $e'), backgroundColor: _kRedDanger),
      );
    }
  }

  // API 2: Lấy danh sách các yêu cầu ĐÃ NHẬN
  Future<void> _fetchReceivedRequests() async {
    setState(() => loadingRequests = true);
    try {
      final results = await _requestApiService.getReceivedRequests();
      setState(() {
        receivedRequests = results;
        loadingRequests = false;
      });
    } catch (e) {
      setState(() => loadingRequests = false);
      print("Lỗi tải yêu cầu truy cập: $e");
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

  // 🔥 HÀM BỔ TRỢ: Dò tìm tên bác sĩ từ dữ liệu records sẵn có dựa trên doctorId
 
  // --- HÀM XỬ LÝ QUY TRÌNH KHI BẤM NÚT ---
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Xác nhận", style: TextStyle(color: _kAccentBlue)),
          )
        ],
      ),
    );
  }

  // 🎯 Đã cập nhật hàm này để truyền tên hiển thị chuẩn vào Dialog xác nhận
  void _showApprovalPopup({
    required AccessRequestModel request,
    required String resolvedDoctorName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (context) => AccessApprovalDialog(
        doctorName: resolvedDoctorName, // 🔥 Hiển thị tên bác sĩ thật trên Pop-up
        hospitalName: "Bệnh viện HP Clinic", 
        recordCount: 1, 
        onConfirm: (String userNote) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang xử lý phê duyệt quyền...'), duration: Duration(seconds: 1)),
          );

          final success = await MedicalRecordBlockchainService.respondToAccessRequest(
            recordId: request.requestedRecordId ?? '',
            staffId: request.doctorId ?? '',          
            status: "approved",
          );

          if (success) {
            _showAlertDialog("Thành công ✅", "Đã cấp quyền xem hồ sơ 24h cho bác sĩ.");
            await _fetchReceivedRequests(); 
          } else {
            _showAlertDialog("Thất bại ❌", "Không thể xử lý yêu cầu. Vui lòng thử lại!");
          }
        },
      ),
    );
  }

  void _handleRejectRequest({required AccessRequestModel request}) async {
    final success = await MedicalRecordBlockchainService.respondToAccessRequest(
      recordId: request.requestedRecordId ?? '',
      staffId: request.doctorId ?? '',
      status: "rejected", 
    );
    
    if (success) {
      _showAlertDialog("Đã từ chối ❌", "Bạn đã từ chối quyền truy cập của bác sĩ.");
      await _fetchReceivedRequests(); 
    } else {
      _showAlertDialog("Thất bại ❌", "Lỗi hệ thống khi thực hiện từ chối.");
    }
  }

  // --- HÀM ĐIỀU HƯỚNG CHUẨN SANG TRANG CHI TIẾT ---
  void _navigateToAdminSection(Map<String, dynamic> recordData) {
    print("➡️ Đang đẩy toàn bộ thông tin hồ sơ sang PatientAdminInfoSection");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientAdminInfoSection(record: recordData),
      ),
    );
  }
    
  @override
  Widget build(BuildContext context) {
    final int totalRecords = records.length;
    final int totalRequests = receivedRequests.length; 

    return Scaffold(
      backgroundColor: _kBgLight,
      appBar: AppBar(
        backgroundColor: _kBgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimaryBlue, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Hồ Sơ Bệnh Án EMR",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _kTextDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.assignment_outlined,
                      count: totalRecords.toString(),
                      label: "Hồ sơ hệ thống",
                      iconColor: _kAccentBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.notifications_none_outlined,
                      count: totalRequests.toString(), 
                      label: "Yêu cầu chờ duyệt",
                      iconColor: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.lock_open_outlined,
                      count: totalRecords > 0 ? "Sepolia" : "N/A", 
                      label: "Mạng Blockchain",
                      iconColor: _kGreenSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!isPatient) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: patientIdController,
                        style: const TextStyle(fontSize: 14, color: _kTextDark),
                        decoration: InputDecoration(
                          hintText: "Nhập mã Patient ID...",
                          hintStyle: const TextStyle(color: _kTextGray),
                          filled: true,
                          fillColor: _kCardLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _kAccentBlue, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.search, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    label: "Hồ sơ của tôi",
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    index: 1,
                    label: "Yêu cầu truy cập",
                    icon: Icons.people_outline,
                    badgeCount: totalRequests, 
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _selectedTab == 0 
                    ? _buildRecordsList() 
                    : _buildRealAccessRequestsList(), 
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String count, required String label, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      height: 100,
      decoration: BoxDecoration(
        color: _kCardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextDark)),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, color: _kTextGray, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon, int badgeCount = 0}) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kAccentBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _kAccentBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? _kAccentBlue : _kTextGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _kAccentBlue : _kTextGray,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- TAB 1: DANH SÁCH HỒ SƠ TỪ BLOCKCHAIN THỰC TẾ ---
  Widget _buildRecordsList() {
    if (loadingRecords) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kAccentBlue),
            SizedBox(height: 16),
            Text("Đang kiểm tra tính toàn vẹn dữ liệu mạng Blockchain...", style: TextStyle(color: _kTextGray, fontSize: 13)),
          ],
        ),
      );
    }

    if (records.isEmpty) {
      return const Center(
        child: Text(
          "Không tìm thấy hồ sơ bệnh án nào cho ID này.\nVui lòng kiểm tra lại!",
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextGray, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildDynamicRecordCard(record);
      },
    );
  }

  Widget _buildDynamicRecordCard(Map<String, dynamic> recordData) {
    String displayDate = "Chưa rõ";
    if (recordData["visitDate"] != null) {
      try {
        DateTime parsedDate = DateTime.parse(recordData["visitDate"]);
        displayDate = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      } catch (_) {}
    }

    final String title = recordData["diagnosis"] ?? "Bệnh án điện tử";
    final String doctor = recordData["doctorName"] ?? "Bác sĩ hệ thống";
    final String treatment = recordData["treatment"] ?? "Theo chỉ định bác sĩ";
    final String network = (recordData["blockchainNetwork"] ?? "Sepolia").toString().toUpperCase();
    final bool isVerified = recordData["blockchainTx"] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kAccentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gavel_rounded, color: _kAccentBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGreenSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kGreenSuccess, width: 0.5),
                      ),
                      child: Text(
                        isVerified ? "Toàn vẹn ($network)" : "Chưa xác minh",
                        style: const TextStyle(color: _kGreenSuccess, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "🗓️ $displayDate    导 $doctor",
                  style: const TextStyle(fontSize: 12, color: _kTextGray),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "Chỉ định: $treatment",
                  style: const TextStyle(fontSize: 13, color: _kTextGray, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: _kAccentBlue, size: 18),
            onPressed: () => _navigateToAdminSection(recordData),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: DANH SÁCH YÊU CẦU THỰC TẾ TỪ API (ĐÃ UPGRADE ĐỔI ID THÀNH TÊN) ---
  Widget _buildRealAccessRequestsList() {
    if (loadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: _kAccentBlue),
      );
    }

    if (receivedRequests.isEmpty) {
      return const Center(
        child: Text(
          "Hộp thư trống.\nBạn chưa nhận được yêu cầu truy cập hồ sơ nào!",
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextGray, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReceivedRequests,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: receivedRequests.length,
        itemBuilder: (context, index) {
          final request = receivedRequests[index];
          final String rId = request.requestedRecordId ?? '';
          final String dId = request.doctorId ?? '';
          
          // 🔥 Thực hiện quét dò tìm tên từ dữ liệu records
         final String finalDoctorName = request.doctorName ?? "Bác sĩ hệ thống";
          final String finalDepartment = request.doctorDepartment ?? "Khoa Tổng Quát";
          
          return _buildRequestCard(
          doctorName: finalDoctorName,       
            department: finalDepartment,
            hospital: "Bệnh viện HP Clinic",
            time: request.time ?? "Vừa xong",
            requestId: request.id ?? "REQ-UNKNOWN",
            reason: request.reason ?? "Không có lý do chi tiết",
            recordId: rId,         
            doctorId: dId,
            requestedRecords: [
              "Mã hồ sơ liên kết: ${request.requestedRecordId ?? 'Chung'}"
            ],
            // 🔥 TRUYỀN HÀM XỬ LÝ KHI PHÊ DUYỆT
            onApprovePressed: () {
              _showApprovalPopup(request: request, resolvedDoctorName: finalDoctorName);
            },
            // 🔥 TRUYỀN HÀM XỬ LÝ KHI TỪ CHỐI
            onRejectPressed: () {
              _handleRejectRequest(request: request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard({
    required String doctorName,
    required String department,
    required String hospital,
    required String time,
    required String requestId,
    required String reason,
    required String recordId,  
    required String doctorId,
    required List<String> requestedRecords,
    required VoidCallback onApprovePressed, 
    required VoidCallback onRejectPressed,  
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kAccentBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.medical_services_outlined, color: _kAccentBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
                    const SizedBox(height: 2),
                    Text("$department · $hospital", style: const TextStyle(fontSize: 13, color: _kTextGray)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: const TextStyle(fontSize: 11, color: _kTextGray)),
                  const SizedBox(height: 2),
                  Text(requestId, style: TextStyle(fontSize: 10, color: _kTextGray.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("LÝ DO YÊU CẦU", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextGray)),
          const SizedBox(height: 6),
          Text(reason, style: const TextStyle(fontSize: 14, color: _kTextDark, height: 1.4)),
          const SizedBox(height: 16),
          const Text("HỒ SƠ ĐƯỢC YÊU CẦU TRUY CẬP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextGray)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: requestedRecords.map((recordInfo) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_outlined, color: _kAccentBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(recordInfo, style: const TextStyle(color: _kTextDark, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD6E4FF), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: _kAccentBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Khi duyệt, bác sĩ nhận token truy cập có thời hạn 24 giờ để đọc hồ sơ từ IPFS. Mọi lần truy cập đều được ghi nhận trên blockchain.",
                    style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprovePressed, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreenSuccess,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_open, size: 16),
                      SizedBox(width: 6),
                      Text("Cho phép truy cập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRejectPressed, 
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRedDanger,
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: const Color(0xFFFEF2F2),
                  ),
                  child: Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cancel_outlined, size: 16, color: _kRedDanger),
                      SizedBox(width: 6),
                      Text("Từ chối", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}