import 'package:flutter/material.dart';
import '../../models/patient.dart';
// import 'package:flutter_application_datlichkham/models/medical_record.dart'; // Import model của bạn

// Giả lập Model MedicalRecord (Nếu bạn đã có file model, hãy dùng file đó và xóa class này)
class MedicalRecord {
  final String patientId;
  final String diagnosis;
  final double urea;
  final double cr;
  final double hba1c;
  final double chol;
  final double tg;
  final double hdl;
  final double ldl;
  final double vldl;
  final double bmi;
  final String status;
  final String doctorNote;
  final DateTime date;

  MedicalRecord({
    required this.patientId,
    required this.diagnosis,
    required this.urea,
    required this.cr,
    required this.hba1c,
    required this.chol,
    required this.tg,
    required this.hdl,
    required this.ldl,
    required this.vldl,
    required this.bmi,
    required this.status,
    required this.doctorNote,
    required this.date,
  });
}

// --- PALETTE MÀU ---
const Color kPrimaryColor = Color(0xFF009688);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;

class MedicalRecordPage extends StatefulWidget {
  final Patient patient;

  MedicalRecordPage({required this.patient});

  @override
  _MedicalRecordPageState createState() => _MedicalRecordPageState();
}

class _MedicalRecordPageState extends State<MedicalRecordPage> {
  // Dữ liệu mẫu
  MedicalRecord record = MedicalRecord(
    patientId: "BN-56301",
    diagnosis: "Tiểu đường Type 2",
    urea: 5.2,
    cr: 1.1,
    hba1c: 7.5, // Cao
    chol: 200,
    tg: 150,
    hdl: 40,
    ldl: 130,
    vldl: 30,
    bmi: 27.5, // Thừa cân
    status: "Mắc bệnh",
    doctorNote: "Cần theo dõi đường huyết thường xuyên, hạn chế tinh bột.",
    date: DateTime.now(),
  );

  // --- HÀM SỬA BỆNH ÁN (LOGIC GIỮ NGUYÊN) ---
  void _editRecord(BuildContext context) {
    // ... (Giữ nguyên logic showDialog sửa bệnh án của bạn ở đây) ...
    // Để code ngắn gọn, mình tập trung vào phần UI hiển thị bên dưới.
    // Bạn hãy copy lại phần _editRecord từ code cũ vào đây nhé.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Hồ Sơ Bệnh Án',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded),
            onPressed: () => _editRecord(context),
            tooltip: "Chỉnh sửa",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. CARD THÔNG TIN BỆNH NHÂN (HEADER)
            _buildPatientHeader(),
            SizedBox(height: 20),

            // 2. CARD CHẨN ĐOÁN
            _buildDiagnosisCard(),
            SizedBox(height: 20),

            // 3. CARD CHỈ SỐ SINH HÓA (CHI TIẾT)
            _buildLabResultsCard(),
            SizedBox(height: 20),

            // 4. GHI CHÚ BÁC SĨ
            _buildDoctorNoteCard(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildPatientHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kPrimaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              widget.patient.name[0],
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.patient.name,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 5),
                Text("Mã BN: ${widget.patient.medicalId}",
                    style: TextStyle(color: Colors.white70)),
                Text("${widget.patient.gender} • ${widget.patient.age} tuổi",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET CHẨN ĐOÁN ---
  Widget _buildDiagnosisCard() {
    Color statusColor = record.status == 'Mắc bệnh' ? Colors.red : Colors.green;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: kCardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CHẨN ĐOÁN CHÍNH",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(record.status,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.local_hospital_rounded,
                  color: kPrimaryColor, size: 30),
              SizedBox(width: 15),
              Expanded(
                child: Text(record.diagnosis,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
            ],
          ),
          Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfo(
                  "BMI", "${record.bmi}", Icons.monitor_weight_outlined),
              _buildMiniInfo(
                  "Ngày khám",
                  "${record.date.day}/${record.date.month}",
                  Icons.calendar_today),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 5),
        Text("$label: ", style: TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- WIDGET CHỈ SỐ XÉT NGHIỆM (LAB) ---
  Widget _buildLabResultsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: kCardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CHỈ SỐ XÉT NGHIỆM",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          SizedBox(height: 20),
          _buildLabRow("HbA1c", record.hba1c, 0, 6.5, " %",
              isHigh: record.hba1c > 6.5), // Cảnh báo nếu > 6.5
          _buildLabRow("Cholesterol", record.chol, 0, 200, " mg/dL"),
          _buildLabRow("Urea", record.urea, 0, 10, " mmol/L"),
          _buildLabRow("Creatinine", record.cr, 0, 1.5, " mg/dL"),
          Divider(),
          _buildLabRow("Triglyceride", record.tg, 0, 200, " mg/dL"),
          _buildLabRow("HDL (Tốt)", record.hdl, 0, 100, " mg/dL",
              color: Colors.green),
          _buildLabRow("LDL (Xấu)", record.ldl, 0, 150, " mg/dL",
              isHigh: record.ldl > 130),
        ],
      ),
    );
  }

  Widget _buildLabRow(
      String label, double value, double min, double max, String unit,
      {bool isHigh = false, Color? color}) {
    // Tính phần trăm để vẽ thanh bar (giới hạn max là 1.0)
    double percentage = (value / (max * 1.2)).clamp(0.0, 1.0);
    Color barColor = color ?? (isHigh ? Colors.redAccent : kPrimaryColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
              Text("$value$unit",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: barColor)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              color: barColor,
              minHeight: 8,
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET GHI CHÚ BÁC SĨ ---
  Widget _buildDoctorNoteCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, color: Colors.amber.shade800),
              SizedBox(width: 10),
              Text("GHI CHÚ ĐIỀU TRỊ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            record.doctorNote,
            style: TextStyle(
                fontSize: 16, height: 1.5, color: Colors.brown.shade800),
          ),
        ],
      ),
    );
  }
}
