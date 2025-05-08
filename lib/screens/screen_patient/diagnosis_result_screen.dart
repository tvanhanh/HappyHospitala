import 'package:flutter/material.dart';
import '../../services/api_medicalRecord.dart'; // Đảm bảo đường dẫn đúng
import 'dart:async';

class DiagnosisResultScreen extends StatefulWidget {
  @override
  _DiagnosisResultScreenState createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  List<Map<String, dynamic>> diagnosisHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMedicalRecords();
  }

  Future<void> fetchMedicalRecords() async {
    final records = await MedicalRecordService.getMedicalRecord();
    setState(() {
      diagnosisHistory = records;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết Quả Chẩn Đoán'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : diagnosisHistory.isEmpty
              ? Center(
                  child: Text(
                    'Không có kết quả chẩn đoán nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: diagnosisHistory.length,
                  itemBuilder: (context, index) {
                    final record = diagnosisHistory[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thông tin cá nhân
                            Text(
                              record['patientName'] ?? 'Chưa có tên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Ngày khám: ${record['createdAt']?.split('T')[0] ?? ''}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Bệnh án: ${record['diagnosis'] ?? 'Tiểu đường'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 10),
                            Divider(),
                            SizedBox(height: 10),
                            // Các chỉ số
                            _buildMedicalField('ID', record['id']),
                            _buildMedicalField('Giới tính', record['gender']),
                            _buildMedicalField('Tuổi', record['age'].toString()),
                            _buildMedicalField('Urea', '${record['urea']} mmol/L'),
                            _buildMedicalField('creatinine', '${record['creatinine']} µmol/L'),
                            _buildMedicalField('HbA1c', '${record['hba1c']} %'),
                            _buildMedicalField('Cholesterol', '${record['cholesterol']} mmol/L'),
                            _buildMedicalField('Triglycerides (TG)', '${record['triglycerides']} mmol/L'),
                            _buildMedicalField('HDL', '${record['hdl']} mmol/L'),
                            _buildMedicalField('LDL', '${record['ldl']} mmol/L'),
                            _buildMedicalField('VLDL', '${record['vldl']} mmol/L'),
                            _buildMedicalField('BMI', '${record['bmi']}'),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Trạng thái: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                Text(
                                  record['status'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(record['status']),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMedicalField(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Mắc bệnh':
        return Colors.red;
      case 'Có nguy cơ':
        return Colors.orange;
      case 'Không mắc':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
