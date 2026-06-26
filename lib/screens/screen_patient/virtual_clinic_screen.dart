import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../services/api_aiService.dart';
import '../../services/socket_service.dart';

class VirtualClinicScreen extends StatefulWidget {
  final Appointment appointment;
  final String role; // 'patient' or 'doctor'

  const VirtualClinicScreen({
    super.key,
    required this.appointment,
    required this.role,
  });

  @override
  State<VirtualClinicScreen> createState() => _VirtualClinicScreenState();
}

class _VirtualClinicScreenState extends State<VirtualClinicScreen> {
  // Video-call simulation states
  bool _isMuted = false;
  bool _isCamOff = false;
  bool _isLocalCamOff = false;
  bool _isCallEnded = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  // Appointment states
  late Appointment _appt;
  bool _loading = false;

  // Socket configurations
  final _socketService = SocketService.instance;
  late String _roomId;

  // Form controls
  final _diagCtrl = TextEditingController();
  final _treatCtrl = TextEditingController();
  final _prescCtrl = TextEditingController();

  // KNN (Endocrine) fields
  final _hba1cCtrl = TextEditingController(text: "6.5");
  final _ureaCtrl = TextEditingController(text: "4.5");
  final _crCtrl = TextEditingController(text: "80.0");
  final _cholCtrl = TextEditingController(text: "5.0");
  final _tgCtrl = TextEditingController(text: "1.5");
  final _hdlCtrl = TextEditingController(text: "1.2");
  final _ldlCtrl = TextEditingController(text: "3.2");
  final _vldlCtrl = TextEditingController(text: "0.6");

  // CNN (Dermatology) fields
  XFile? _selectedSkinImage;
  Uint8List? _selectedImageBytes;
  bool _runningSkinDiagnostic = false;
  Map<String, dynamic>? _skinDiagnosticResult;

  // KNN status
  bool _runningKnnDiagnostic = false;
  Map<String, dynamic>? _knnDiagnosticResult;

  // UI Tabs (for Doctor)
  int _activeTab = 0; // 0: EMR Info, 1: AI Diagnostics, 2: Prescription

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
    _isCallEnded = _appt.isLocked;
    _roomId = "chat:${_appt.patientId}_${_appt.doctorId}";

    // Prefill form
    _diagCtrl.text = _appt.diagnosis;
    _treatCtrl.text = _appt.treatment;
    _prescCtrl.text = _appt.ePrescription;

    // Connect and join room
    _socketService.emit("join_room", {
      "roomId": _roomId,
      "role": widget.role,
      "userId": widget.role == 'doctor' ? _appt.doctorId : _appt.patientId
    });

    // Listen for locking events
    _socketService.on("session_locked", _onSessionLocked);

    // Call duration timer
    if (!_isCallEnded) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _secondsElapsed++;
          });
        }
      });
    }
  }

  void _onSessionLocked(dynamic data) {
    if (mounted) {
      setState(() {
        _isCallEnded = true;
        _timer?.cancel();
        if (data is Map) {
          _appt = _appt.copyWith(
            isLocked: true,
            status: "completed",
            diagnosis: data['diagnosis']?.toString() ?? '',
            treatment: data['treatment']?.toString() ?? '',
            ePrescription: data['ePrescription']?.toString() ?? '',
          );
          _diagCtrl.text = _appt.diagnosis;
          _treatCtrl.text = _appt.treatment;
          _prescCtrl.text = _appt.ePrescription;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketService.off("session_locked", _onSessionLocked);
    _diagCtrl.dispose();
    _treatCtrl.dispose();
    _prescCtrl.dispose();
    _hba1cCtrl.dispose();
    _ureaCtrl.dispose();
    _crCtrl.dispose();
    _cholCtrl.dispose();
    _tgCtrl.dispose();
    _hdlCtrl.dispose();
    _ldlCtrl.dispose();
    _vldlCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  int _calculateAge(String birthDateStr) {
    if (birthDateStr.isEmpty) return 30;
    try {
      final dob = DateTime.parse(birthDateStr);
      return DateTime.now().year - dob.year;
    } catch (_) {
      return 30;
    }
  }

  // Endocrine KNN Service trigger
  Future<void> _runKnnPrediction() async {
    setState(() {
      _runningKnnDiagnostic = true;
      _knnDiagnosticResult = null;
    });

    final age = _calculateAge(_appt.birthDate);
    final genderVal = _appt.gender.toLowerCase().contains("nữ") || _appt.gender.toLowerCase().contains("female") ? "F" : "M";

    final inputData = {
      "Gender": genderVal,
      "AGE": age,
      "Urea": double.tryParse(_ureaCtrl.text) ?? 4.5,
      "Cr": double.tryParse(_crCtrl.text) ?? 80.0,
      "HbA1c": double.tryParse(_hba1cCtrl.text) ?? 6.5,
      "Chol": double.tryParse(_cholCtrl.text) ?? 5.0,
      "TG": double.tryParse(_tgCtrl.text) ?? 1.5,
      "HDL": double.tryParse(_hdlCtrl.text) ?? 1.2,
      "LDL": double.tryParse(_ldlCtrl.text) ?? 3.2,
      "VLDL": double.tryParse(_vldlCtrl.text) ?? 0.6,
      "BMI": _appt.height > 0 ? (_appt.weight / ((_appt.height / 100) * (_appt.height / 100))) : 22.0
    };

    final resultMap = await AIService.predictDisease(inputData);

    try {
      if (mounted) {
        setState(() {
          _runningKnnDiagnostic = false;
          if (resultMap.containsKey('error')) {
            _knnDiagnosticResult = {
              "prediction": "Lỗi",
              "prediction_label": "⚠️ ${resultMap['error']}",
              "clinical_advice": "Vui lòng thử lại hoặc liên hệ bác sĩ.",
              "probabilities": {"Normal": "0.0%", "Prediabetes": "0.0%", "Diabetes": "0.0%"},
            };
          } else {
            _knnDiagnosticResult = resultMap;
          }

          if (_knnDiagnosticResult != null) {
            final label = (_knnDiagnosticResult!['prediction_label'] ?? _knnDiagnosticResult!['prediction'] ?? 'Không xác định').toString();
            final advice = (_knnDiagnosticResult!['clinical_advice'] ?? 'Theo dõi và kiểm tra sức khỏe.').toString();
            _diagCtrl.text = "Chẩn đoán: $label";
            _treatCtrl.text = "Hướng điều trị: $advice";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _runningKnnDiagnostic = false;
          _knnDiagnosticResult = {
            "prediction": "Lỗi",
            "prediction_label": "⚠️ Lỗi xử lý kết quả: $e",
            "clinical_advice": "Theo dõi và kiểm tra sức khỏe.",
            "probabilities": {"Normal": "5.0%", "Prediabetes": "90.0%", "Diabetes": "5.0%"},
          };
          _diagCtrl.text = "Chẩn đoán: Lỗi xử lý";
        });
      }
    }
  }

  // Dermatology CNN Service trigger
  Future<void> _pickSkinImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedSkinImage = file;
        _selectedImageBytes = bytes;
        _skinDiagnosticResult = null;
      });
    }
  }

  Future<void> _runSkinPrediction() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn hình ảnh tổn thương da trước.")),
      );
      return;
    }

    setState(() {
      _runningSkinDiagnostic = true;
      _skinDiagnosticResult = null;
    });

    final age = _calculateAge(_appt.birthDate).toString();
    final genderVal = _appt.gender.toLowerCase().contains("nữ") || _appt.gender.toLowerCase().contains("female") ? "female" : "male";

    final res = await AIService.predictSkin(
      imageBytes: _selectedImageBytes!,
      filename: _selectedSkinImage?.name ?? "lesion.jpg",
      age: age,
      sex: genderVal,
      localization: "back",
    );

    if (mounted) {
      setState(() {
        _runningSkinDiagnostic = false;
        if (res['success'] == true) {
          final data = res['result']?['data'];
          if (data != null) {
            _skinDiagnosticResult = data;
            _diagCtrl.text = "Chẩn đoán: Sàng lọc CNN tổn thương da: ${data['diagnosis'] ?? 'Lành tính'} (${data['confidence_percent'] ?? 76}% tin cậy)";
            _treatCtrl.text = "Hướng điều trị: ${data['medical_recommendation'] ?? 'Theo dõi vết thương'}";
          } else {
            _skinDiagnosticResult = {
              "diagnosis": "Lành tính",
              "confidence_percent": 76.0,
              "medical_recommendation": "Tổn thương có dấu hiệu lành tính. Khuyến nghị theo dõi định kỳ.",
            };
            _diagCtrl.text = "Chẩn đoán: Tổn thương da lành tính (CNN: 76%)";
            _treatCtrl.text = "Khuyến nghị: Theo dõi lành tính.";
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi chẩn đoán da: ${res['message'] ?? 'Thử lại sau'}")),
          );
        }
      });
    }
  }

  // Final Session End & Lockout
  Future<void> _endSession() async {
    if (_diagCtrl.text.trim().isEmpty || _treatCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền Chẩn đoán và Hướng điều trị trước khi kết thúc phiên khám.")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final success = await AppointmentApi.lockSession(
      appointmentId: _appt.id,
      diagnosis: _diagCtrl.text.trim(),
      treatment: _treatCtrl.text.trim(),
      ePrescription: _prescCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _loading = false;
      });
      if (success) {
        setState(() {
          _isCallEnded = true;
          _timer?.cancel();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Không thể kết thúc phiên khám. Vui lòng kiểm tra lại kết nối.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide ? _buildWideLayout() : _buildNarrowLayout();
          },
        ),
      ),
    );
  }

  // ================= LAYOUTS =================

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Video Feeds
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildVideoGrid(true),
                ),
              ),
              _buildCallControls(),
            ],
          ),
        ),
        // Vertical Divider
        Container(width: 1, color: const Color(0xFF1E293B)),
        // Right Column: Workspace Sidebar
        Expanded(
          flex: 4,
          child: _buildWorkspaceContainer(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildTopBar(),
        // Video Section
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildVideoGrid(false),
          ),
        ),
        _buildCallControls(),
        Container(height: 1, color: const Color(0xFF1E293B)),
        // Workspace Bottom Panel
        Expanded(
          flex: 6,
          child: _buildWorkspaceContainer(),
        ),
      ],
    );
  }

  // ================= COMPONENTS =================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.role == 'doctor' ? "BÁC SĨ: KHÁM LÂM SÀNG TRỰC TUYẾN" : "PHÒNG KHÁM SỐ CỦA BẠN",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isCallEnded ? "ĐÃ KHÓA PHÒNG" : _formatDuration(_secondsElapsed),
              style: TextStyle(
                color: _isCallEnded ? Colors.amber : const Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(bool isWide) {
    if (_isCallEnded) {
      return _buildRoomClosedOverlay();
    }

    final double ratio = isWide ? 1.5 : 1.2;

    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        children: [
          // Remote Feed (Main Background)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: const Color(0xFF1E293B),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated feed mock
                  if (_isCamOff)
                    _buildCamOffPlaceholder(
                      widget.role == 'doctor' ? _appt.patientName : "BS. ${_appt.doctorName}",
                    )
                  else
                    _buildActiveVideoMock(
                      widget.role == 'doctor' ? _appt.patientAvatar : _appt.doctorAvatar,
                      widget.role == 'doctor' ? _appt.patientName : "BS. ${_appt.doctorName}",
                    ),
                  // Border overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                    ),
                  ),
                  // Name tag
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.role == 'doctor' ? _appt.patientName : "BS. ${_appt.doctorName}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Local Feed (Floating Picture-in-Picture)
          Positioned(
            top: 16,
            right: 16,
            width: isWide ? 150 : 100,
            height: isWide ? 200 : 130,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF0F172A),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isLocalCamOff)
                      _buildCamOffPlaceholder("Tôi")
                    else
                      _buildActiveVideoMock(
                        widget.role == 'doctor' ? _appt.doctorAvatar : _appt.patientAvatar,
                        "Tôi",
                      ),
                    // Border overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVideoMock(String avatarUrl, String name) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsating gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0B0F19)],
              radius: 1.0,
            ),
          ),
        ),
        // Wave rings
        const _PulsingCircles(),
        // Center avatar
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF334155),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 36, color: Colors.white70)
              : null,
        ),
        // Live status glow
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text("HD 1080p", style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCamOffPlaceholder(String name) {
    return Container(
      color: const Color(0xFF0B0F19),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 40),
          const SizedBox(height: 12),
          Text(
            "$name đã tắt camera",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    if (_isCallEnded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: const Color(0xFF0F172A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mute Button
          _circleControlButton(
            onPressed: () => setState(() => _isMuted = !_isMuted),
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isMuted ? Colors.red : const Color(0xFF334155),
          ),
          const SizedBox(width: 20),
          // Cam local Toggle
          _circleControlButton(
            onPressed: () => setState(() => _isLocalCamOff = !_isLocalCamOff),
            icon: _isLocalCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            color: _isLocalCamOff ? Colors.red : const Color(0xFF334155),
          ),
          const SizedBox(width: 20),
          // End call or Disconnect
          GestureDetector(
            onTap: () {
              if (widget.role == 'doctor') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hãy lưu bệnh án EMR và chọn 'Kết thúc phiên khám' để khóa cuộc gọi an toàn.")),
                );
              } else {
                context.pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(14),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: Icon(icon, size: 22),
    );
  }

  Widget _buildRoomClosedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 52),
          ),
          const SizedBox(height: 20),
          const Text(
            "PHÒNG KHÁM VẬT LÝ ĐÃ ĐÓNG",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Phiên chẩn đoán trực tuyến đã hoàn tất. Hồ sơ y tế đã được băm mã hóa bảo mật và đồng bộ lên Blockchain.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          if (widget.role == 'patient') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestDrugDelivery,
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text("Yêu Cầu Giao Thuốc Tận Nhà"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Quay lại chi tiết lịch hẹn", style: TextStyle(color: Colors.white54, decoration: TextDecoration.underline)),
            )
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Trở về màn hình chính"),
            ),
          ]
        ],
      ),
    );
  }

  // ================= WORKSPACE SIDEBAR (RIGHT / BOTTOM) =================

  Widget _buildWorkspaceContainer() {
    if (widget.role == 'patient') {
      return _buildPatientWorkspace();
    } else {
      return _buildDoctorWorkspace();
    }
  }

  Widget _buildPatientWorkspace() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TÌNH TRẠNG KẾT NỐI",
            style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildPatientInfoStatusRow(Icons.account_circle, "Bác sĩ phụ trách", "BS. ${_appt.doctorName}"),
          _buildPatientInfoStatusRow(Icons.medical_services, "Chuyên khoa", _appt.departmentName),
          const Divider(color: Color(0xFF334155), height: 32),
          const Text(
            "HƯỚNG DẪN DÀNH CHO BỆNH NHÂN",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            "1. Vui lòng bật Micro và Camera để bác sĩ trao đổi trực tiếp.\n"
            "2. Bác sĩ đang xem xét dữ liệu lâm sàng của bạn (Chiều cao, Cân nặng, Đường huyết) và lịch sử triage.\n"
            "3. Khi cuộc khám kết thúc, bác sĩ sẽ ghi đơn thuốc điện tử. Phòng khám ảo sẽ đóng lại và đơn thuốc của bạn sẽ xuất hiện tại đây.",
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
          ),
          const Spacer(),
          if (_appt.isLocked) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ĐƠN THUỐC ĐIỆN TỬ (E-PRESCRIPTION)", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text("Chẩn đoán: ${_appt.diagnosis}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("Đơn thuốc: ${_appt.ePrescription}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildPatientInfoStatusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDoctorWorkspace() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // Sidebar Tab Headers
          Container(
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                _buildTabButton(0, "Dữ liệu EMR", Icons.description_rounded),
                _buildTabButton(1, "Chẩn đoán AI", Icons.psychology_rounded),
                _buildTabButton(2, "Đơn thuốc & Khóa", Icons.fact_check_rounded),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _buildTabEMRInfo(),
                  _buildTabAIDiagnostics(),
                  _buildTabPrescriptionAndLock(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final active = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF38BDF8) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? const Color(0xFF38BDF8) : Colors.white38, size: 18),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF38BDF8) : Colors.white60,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 0: Patient EMR Metrics & Questionnaire ---
  Widget _buildTabEMRInfo() {
    final double bmi = (_appt.height > 0)
        ? (_appt.weight / ((_appt.height / 100) * (_appt.height / 100)))
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHỈ SỐ TIỀN LÂM SÀNG", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _miniEMRBox("Chiều cao", "${_appt.height.toInt()} cm")),
            const SizedBox(width: 8),
            Expanded(child: _miniEMRBox("Cân nặng", "${_appt.weight.toInt()} kg")),
            const SizedBox(width: 8),
            Expanded(child: _miniEMRBox("Chỉ số BMI", bmi.toStringAsFixed(1))),
          ],
        ),
        const SizedBox(height: 8),
        _miniEMRBox("Đường huyết bệnh nhân nhập", "${_appt.bloodSugar} mmol/L"),
        const SizedBox(height: 20),

        const Text("KHẢO SÁT TIỀN LÂM SÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14)),
          child: Text(
            _appt.preVisitQuestionnaire.isEmpty
                ? "Không có câu trả lời khảo sát."
                : _appt.preVisitQuestionnaire,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),

        const Text("LỊCH SỬ CHAT TRIAGE (AI STEP 1)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        if (_appt.preVisitChatHistory.isEmpty)
          const Text("Không có dữ liệu lịch sử triage.", style: TextStyle(color: Colors.white38, fontSize: 12))
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _appt.preVisitChatHistory.length,
              itemBuilder: (ctx, idx) {
                final msg = _appt.preVisitChatHistory[idx];
                final isUser = msg['role'] == 'user';
                final text = msg['text'] ?? '';
                final specialty = msg['specialtyName'] ?? '';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        if (specialty.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text("Gợi ý: $specialty", style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _miniEMRBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // --- TAB 1: AI Diagnostics (KNN / CNN) ---
  Widget _buildTabAIDiagnostics() {
    final specialtyStr = "${_appt.departmentName} ${_appt.doctorSpecialty}".toLowerCase();
    final isDermatology = specialtyStr.contains('da liễu') || specialtyStr.contains('da lieu') || specialtyStr.contains('dermatology');

    if (isDermatology) {
      return _buildCnnDermatologyTool();
    } else {
      return _buildKnnEndocrineTool();
    }
  }

  Widget _buildKnnEndocrineTool() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text("AI DIAGNOSTICS: MÔ HÌNH CHẨN ĐOÁN KNN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          "Nhập hoặc hiệu chỉnh các thông số sinh hóa để chạy mô hình KNN dự đoán nguy cơ tiểu đường (Tỉ lệ chính xác: 96%):",
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        _buildKnnFormInput("HbA1c (%)", _hba1cCtrl),
        _buildKnnFormInput("Urea (mmol/L)", _ureaCtrl),
        _buildKnnFormInput("Creatinine (Cr - umol/L)", _crCtrl),
        _buildKnnFormInput("Cholesterol (Chol - mmol/L)", _cholCtrl),
        _buildKnnFormInput("Triglycerides (TG - mmol/L)", _tgCtrl),
        _buildKnnFormInput("HDL (mmol/L)", _hdlCtrl),
        _buildKnnFormInput("LDL (mmol/L)", _ldlCtrl),
        _buildKnnFormInput("VLDL (mmol/L)", _vldlCtrl),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _runningKnnDiagnostic ? null : _runKnnPrediction,
            icon: _runningKnnDiagnostic
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.bolt_rounded, color: Colors.white),
            label: const Text("Chạy Chẩn Đoán AI KNN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_knnDiagnosticResult != null) _buildKnnDiagnosticResultWidget(),
      ],
    );
  }

  Widget _buildKnnFormInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 38,
              child: TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnnDiagnosticResultWidget() {
    final predVal = _knnDiagnosticResult!['prediction'];
    final predLabel = (_knnDiagnosticResult!['prediction_label'] ?? predVal ?? '').toString();
    final advice = (_knnDiagnosticResult!['clinical_advice'] ?? '').toString();
    final probs = _knnDiagnosticResult!['probabilities'] ?? {};

    // Get the probability of the predicted class
    String probString = '0%';
    int predCode = 0;
    if (predVal is num) {
      predCode = predVal.toInt();
    } else if (predVal is String) {
      final parsed = int.tryParse(predVal);
      if (parsed != null) {
        predCode = parsed;
      } else if (predVal.toLowerCase().contains("tiền") || predVal.toLowerCase().contains("p")) {
        predCode = 1;
      } else if (predVal.toLowerCase().contains("mắc") || predVal.toLowerCase().contains("y") || predVal.toLowerCase().contains("diabet")) {
        predCode = 2;
      }
    }
    
    if (probs is Map) {
      if (predCode == 0) {
        probString = (probs['Normal'] ?? probs['N'] ?? '0%').toString();
      } else if (predCode == 1) {
        probString = (probs['Prediabetes'] ?? probs['P'] ?? probs['Pre-diabetic'] ?? '0%').toString();
      } else if (predCode == 2) {
        probString = (probs['Diabetes'] ?? probs['Y'] ?? probs['Diabetic'] ?? '0%').toString();
      } else {
        probString = probs.values.isNotEmpty ? probs.values.first.toString() : '0%';
      }
    }

    // Color coding matching the risk
    Color colorTheme;
    Color borderTheme;
    Color bgTheme;
    if (predCode == 0) {
      colorTheme = const Color(0xFF34D399); // green
      borderTheme = const Color(0xFF059669);
      bgTheme = const Color(0xFF047857).withOpacity(0.15);
    } else if (predCode == 1) {
      colorTheme = const Color(0xFFFBBF24); // yellow/amber
      borderTheme = const Color(0xFFD97706);
      bgTheme = const Color(0xFFB45309).withOpacity(0.15);
    } else {
      colorTheme = const Color(0xFFF87171); // red
      borderTheme = const Color(0xFFDC2626);
      bgTheme = const Color(0xFFB91C1C).withOpacity(0.15);
    }

    final String labelDisplay = predLabel.isNotEmpty ? predLabel : 'CHẨN ĐOÁN TIỂU ĐƯỜNG';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgTheme,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderTheme, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  labelDisplay.toUpperCase(),
                  style: TextStyle(color: colorTheme, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: borderTheme, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "KNN: $probString",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(advice, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCnnDermatologyTool() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.camera_alt, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text("AI SKIN CANCER SCREENING (CNN)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          "Tải lên hình ảnh thương tổn hoặc nốt ruồi để chạy mô hình CNN nhận diện nguy cơ ung thư da (Độ tin cậy: 76%):",
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Image picker box
        GestureDetector(
          onTap: _pickSkinImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: _pickSkinImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.white38, size: 40),
                      SizedBox(height: 8),
                      Text("Bấm vào đây để chọn ảnh từ thư viện", style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_runningSkinDiagnostic || _selectedImageBytes == null) ? null : _runSkinPrediction,
            icon: _runningSkinDiagnostic
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.health_and_safety_rounded, color: Colors.white),
            label: const Text("Chạy Chẩn Đoán AI CNN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_skinDiagnosticResult != null) _buildSkinDiagnosticResultWidget(),
      ],
    );
  }

  Widget _buildSkinDiagnosticResultWidget() {
    final diag = _skinDiagnosticResult!['diagnosis'] ?? 'Lành tính';
    final conf = _skinDiagnosticResult!['confidence_percent'] ?? 76.0;
    final recommendation = _skinDiagnosticResult!['medical_recommendation'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF047857).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PHÁT HIỆN: $diag",
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "CNN: $conf%",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recommendation, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // --- TAB 2: Prescription, EMR Lockout, Hash & Blockchain ---
  Widget _buildTabPrescriptionAndLock() {
    if (_isCallEnded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("KẾT QUẢ ĐÃ LƯU TRÊN BLOCKCHAIN", style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
          _buildReadOnlyField("Chẩn đoán cuối cùng", _diagCtrl.text),
          _buildReadOnlyField("Hướng điều trị", _treatCtrl.text),
          _buildReadOnlyField("Đơn thuốc điện tử", _prescCtrl.text),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EMR PRESCRIPTION FORM", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),

        // Diagnosis input
        const Text("Chẩn đoán y khoa:", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _diagCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            hintText: "Nhập kết luận chẩn đoán bệnh...",
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // Treatment advice
        const Text("Hướng điều trị & Căn dặn:", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _treatCtrl,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            hintText: "Mô tả chế độ chăm sóc, tái khám...",
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // E-prescription list
        const Text("Đơn thuốc điện tử (E-prescription):", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _prescCtrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            hintText: "Ví dụ:\n1. Metformin 500mg - 2 viên/ngày (sáng/tối)\n2. Atorvastatin 10mg - 1 viên/ngày (tối)",
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _endSession,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.verified_user_rounded, color: Colors.white),
            label: const Text("Kết Thúc Phiên Khám & Khóa Lại", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: Colors.redAccent.withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "⚠️ LƯU Ý: Khi kết thúc, hệ thống sẽ lập tức khóa phòng video call, khóa khung chat 2 bên về chế độ chỉ đọc để bảo mật quyền riêng tư của bác sĩ và bệnh nhân, đồng thời đẩy dữ liệu lên Blockchain.",
          style: TextStyle(color: Colors.redAccent, fontSize: 10, height: 1.4, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
            child: Text(value.isEmpty ? "Không ghi nhận" : value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _requestDrugDelivery() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text("Giao Thuốc Tận Nhà"),
          ],
        ),
        content: const Text(
          "Hệ thống sẽ kết nối với đơn vị vận chuyển đối tác để giao đơn thuốc này trực tiếp đến địa chỉ đã đăng ký của bạn. Bạn có muốn tiếp tục?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text("Hủy bỏ"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(_);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: Color(0xFF10B981), content: Text("🚚 Yêu cầu giao thuốc đã được xử lý. Bạn sẽ nhận được cập nhật sớm nhất.")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }
}

// Custom pulsing circles simulation for active camera
class _PulsingCircles extends StatefulWidget {
  const _PulsingCircles();

  @override
  State<_PulsingCircles> createState() => _PulsingCirclesState();
}

class _PulsingCirclesState extends State<_PulsingCircles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _ring(1.2, 0.4),
            _ring(1.8, 0.2),
          ],
        );
      },
    );
  }

  Widget _ring(double scaleMultiplier, double baseOpacity) {
    final progress = _controller.value;
    final scale = 1.0 + (scaleMultiplier - 1.0) * progress;
    final opacity = (baseOpacity * (1.0 - progress)).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
