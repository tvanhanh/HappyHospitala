import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/doctor_home_screen.dart';
import '../../services/api_medicalRecord.dart';
import 'dart:async';

// --- PALETTE MÀU CHUYÊN NGHIỆP ---
const Color kPrimaryColor = Color(0xFF1565C0); // Xanh dương đậm
const Color kBackgroundColor = Color(0xFFF0F4F8);
const Color kWarningColor = Color(0xFFFF9800);
const Color kCriticalColor = Color(0xFFE53935);
const Color kSafeColor = Color(0xFF4CAF50);
const Color kTitleColor = Color(0xFF263238);
const Color kTextPrimary = Color(0xFF1A237E);

class DiagnosisResultScreen extends StatefulWidget {
  @override
  _DiagnosisResultScreenState createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  // --- LOGIC GIỮ NGUYÊN ---
  List<Map<String, dynamic>> diagnosisHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMockRecordsIfEmpty();
  }

  Future<void> fetchMedicalRecords() async {
    final records = await MedicalRecordService.getMedicalRecord();
    setState(() {
      diagnosisHistory = records;
    });
    _loadMockRecordsIfEmpty();
  }

  // ✅ DỮ LIỆU GIẢ LẬP ĐỂ LÀM UI
  Future<void> _loadMockRecordsIfEmpty() async {
    if (diagnosisHistory.isEmpty) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        diagnosisHistory = [
          {
            'patientName': "Lưu Thị Chiến",
            'diagnosis': "Tiểu đường Type 2",
            'age': 35,
            'status': "Mắc bệnh",
            'hba1c': 7.8,
            'bmi': 27.5,
            'cholesterol': 220,
            'createdAt': DateTime(2025, 11, 28).toIso8601String(),
            'id': 'MR001',
            'doctorNote': 'Chế độ ăn kiêng. (Lần gần nhất)',
            'dateString': '28/11/2025'
          },
          {
            'patientName': "Lưu Thị Chiến",
            'diagnosis': "Theo dõi nguy cơ",
            'age': 35,
            'status': "Có nguy cơ",
            'hba1c': 6.9,
            'bmi': 27.0,
            'cholesterol': 210,
            'createdAt': DateTime(2025, 6, 15).toIso8601String(),
            'id': 'MR002',
            'doctorNote': 'Giảm cân cấp thiết.',
            'dateString': '15/06/2025'
          },
        ];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }
  // --- HẾT LOGIC GIỮ NGUYÊN ---

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text('Kết Quả Chẩn Đoán',
                style: TextStyle(fontWeight: FontWeight.bold))),
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (diagnosisHistory.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Lịch Sử Bệnh Án')),
        body: _buildEmptyState(),
      );
    }

    // Lấy thông tin cố định của bệnh nhân từ hồ sơ gần nhất
    final latestRecord = diagnosisHistory.first;
    final patientName = latestRecord['patientName'];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(patientName ?? 'Hồ Sơ Bệnh Án',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(Icons.print),
              onPressed: () {},
              tooltip: "Xuất báo cáo PDF"),
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchMedicalRecords),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchMedicalRecords,
        color: kPrimaryColor,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // 1. TÓM TẮT TRẠNG THÁI HIỆN TẠI
            _buildSummaryHeader(latestRecord),
            SizedBox(height: 30),

            // 2. LỊCH SỬ KHÁM (Timeline)
            Text("LỊCH SỬ CÁC LẦN KHÁM",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600)),
            SizedBox(height: 10),

            ...diagnosisHistory
                .map((record) => _buildVisitSummaryCard(context, record))
                .toList(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON: HEADER TÓM TẮT ---
  Widget _buildSummaryHeader(Map<String, dynamic> record) {
    Color riskColor = _getStatusColor(record['status']);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KẾT QUẢ GẦN NHẤT: ${record['diagnosis']}",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor)),
          Divider(height: 25),
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, size: 30, color: riskColor),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TRẠNG THÁI NGUY CƠ",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(record['status'].toUpperCase(),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: riskColor)),
                ],
              )
            ],
          ),
          Divider(height: 25),

          // Chỉ số quan trọng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickMetric(
                  'HbA1c',
                  '${record['hba1c']} %',
                  record['hba1c'] > 7.0 ? kCriticalColor : kSafeColor,
                  Icons.bloodtype),
              _buildQuickMetric(
                  'BMI',
                  record['bmi'].toStringAsFixed(1),
                  record['bmi'] > 25 ? kWarningColor : kSafeColor,
                  Icons.monitor_weight_rounded),
              _buildQuickMetric(
                  'Chol.',
                  record['cholesterol'].toStringAsFixed(0),
                  record['cholesterol'] > 200 ? kCriticalColor : kSafeColor,
                  Icons.favorite_rounded),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: THẺ TÓM TẮT LẦN KHÁM ---
  Widget _buildVisitSummaryCard(
      BuildContext context, Map<String, dynamic> record) {
    Color statusColor = _getStatusColor(record['status']);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Chuyển sang màn hình chi tiết cho lần khám này
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Xem chi tiết bệnh án ${record['id']}')));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ngày tháng và chẩn đoán
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record['dateString'] ?? '---',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 15)),
                    SizedBox(height: 4),
                    Text(record['diagnosis'] ?? 'Lần khám',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: kTitleColor)),
                    SizedBox(height: 4),
                    Text('Ghi chú: ${record['doctorNote']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),

                // Trạng thái và Icon
                Row(
                  children: [
                    _buildStatusChip(record['status'], statusColor),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HÀM HỖ TRỢ ĐỊNH DẠNG ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined,
              size: 80, color: Colors.grey.shade300),
          SizedBox(height: 15),
          Text('Chưa có kết quả chẩn đoán nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildQuickMetric(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Mắc bệnh':
        return kCriticalColor;
      case 'Có nguy cơ':
        return kWarningColor;
      case 'Không mắc':
        return kSafeColor;
      default:
        return Colors.blue;
    }
  }
}
