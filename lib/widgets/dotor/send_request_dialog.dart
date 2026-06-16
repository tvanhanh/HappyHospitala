import 'package:flutter/material.dart';
import '../../services/api_medicalRecordBlockchain.dart';

// Đồng bộ hệ màu Light Mode trắng xanh
const Color _kBgLight = Color(0xFFF8FAFC);
const Color _kCardLight = Color(0xFFFFFFFF);
const Color _kAccentBlue = Color(0xFF3B82F6);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextGray = Color(0xFF64748B);
const Color _kWarningYellow = Color(0xFFD97706);

class SendRequestDialog extends StatefulWidget {
  final String recordId;
  // 🔑 BỔ SUNG: Nhận thêm patientId và patientName từ trang trước truyền sang
  final String patientId;
  final String patientName;

  
  final Function(String patientId, String reason)? onSubmit;

  const SendRequestDialog({
    super.key, 
    required this.recordId, 
    required this.patientId,   
    required this.patientName,
    this.onSubmit,
  });

  @override
  State<SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<SendRequestDialog> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController(); // Quản lý ô nhập tên
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 🔑 Tự động đổ dữ liệu thật từ trang trước vào các ô Input
    _patientIdController.text = widget.patientId;
    _patientNameController.text = widget.patientName;
  }

  Future<void> _handleExecuteRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đang gửi yêu cầu xác thực tới bệnh nhân..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Gọi API service thật kèm theo lý do bác sĩ nhập
      bool isSuccess = await MedicalRecordBlockchainService.sendAccessRequest(
        widget.recordId,
        reason: _reasonController.text.trim(),

      );
      
      if (isSuccess && mounted) {
        if (widget.onSubmit != null) {
          widget.onSubmit!(
            _patientIdController.text.trim(),
            _reasonController.text.trim(),
          );
        }

        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text("Gửi thành công", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              "Yêu cầu truy cập hồ sơ của bệnh nhân ${_patientNameController.text} đã được ghi nhận vào hệ thống phi tập trung.",
              style: const TextStyle(fontSize: 13, height: 1.4, color: _kTextDark),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kCardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 460, 
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TIÊU ĐỀ DIALOG ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_open_outlined, color: _kAccentBlue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Gửi yêu cầu xem hồ sơ",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _kTextGray, size: 20),
                    splashRadius: 20,
                  )
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Hệ thống sẽ gửi thông báo phê duyệt trực tiếp đến ứng dụng cá nhân của bệnh nhân chỉ định.",
                style: TextStyle(fontSize: 13, color: _kTextGray, height: 1.4),
              ),
              const SizedBox(height: 20),
              
              // --- INPUT: MÃ BỆNH NHÂN (KHÓA READ-ONLY VÌ ĐÃ CÓ DATA REAL) ---
              const Text("Mã bệnh nhân (ID)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _patientIdController,
                enabled: false, // Khóa lại tránh bác sĩ sửa nhầm ID của ca đang xem
                style: const TextStyle(fontSize: 14, color: _kTextDark, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT: TÊN BỆNH NHÂN (READ-ONLY) ---
              const Text("Tên bệnh nhân", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _patientNameController,
                enabled: false, // Khóa lại chỉ để hiển thị minh bạch thông tin
                style: const TextStyle(fontSize: 14, color: _kTextDark, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT: LÝ DO YÊU CẦU ---
              const Text("Lý do yêu cầu truy cập", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 14, color: _kTextDark),
                decoration: InputDecoration(
                  hintText: "Nhập lý do lâm sàng cần xem lại tài liệu gốc...",
                  hintStyle: TextStyle(color: _kTextGray.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: _kBgLight,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAccentBlue)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập lý do rõ ràng để bệnh nhân duyệt nhanh hơn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- BANNER CẢNH BÁO BLOCKCHAIN ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kWarningYellow.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kWarningYellow.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _kWarningYellow, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Mọi yêu cầu xin quyền và lịch sử phản hồi đều được ký số lưu vết minh bạch, chống chối bỏ trên mạng lưới.",
                        style: TextStyle(fontSize: 12, color: _kWarningYellow.withOpacity(0.95), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- NHÓM NÚT ĐIỀU KHIỂN CHÂN DIALOG ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Hủy", style: TextStyle(color: _kTextGray, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleExecuteRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      elevation: 0,
                    ),
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 14),
                    label: Text(_isLoading ? "Đang xử lý..." : "Gửi yêu cầu", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}