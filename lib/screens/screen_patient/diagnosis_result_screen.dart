import 'package:flutter/material.dart';
import 'dart:math';

class DiagnosisResultScreen extends StatelessWidget {
  // Dữ liệu giả lập cho lịch sử khám bệnh
  final List<Map<String, dynamic>> diagnosisHistory = List.generate(
    1, // Tạo 3 bản ghi giả lập
        (index) {
      final random = Random();
      return {
        'name': 'Nguyễn Văn ${String.fromCharCode(65 + index)}', // Tên: Nguyễn Văn A, B, C
        'date': '2025-04-${10 + index}', // Ngày khám: 2025-04-10, 11, 12
        'disease': 'Tiểu đường', // Bệnh án mặc định
        'id': 'PAT${100 + index}', // ID: PAT100, PAT101, PAT102
        'gender': ['Nam', 'Nữ'][random.nextInt(2)], // Giới tính: Nam hoặc Nữ
        'age': 30 + random.nextInt(40), // Tuổi: 30-70
        'urea': (5 + random.nextDouble() * 5).toStringAsFixed(1), // Urea: 5-10 mmol/L
        'cr': (60 + random.nextInt(40)).toString(), // Cr: 60-100 µmol/L
        'hba1c': (5 + random.nextDouble() * 5).toStringAsFixed(1), // HbA1c: 5-10%
        'chol': (3 + random.nextDouble() * 3).toStringAsFixed(1), // Chol: 3-6 mmol/L
        'tg': (1 + random.nextDouble() * 2).toStringAsFixed(1), // TG: 1-3 mmol/L
        'hdl': (0.8 + random.nextDouble() * 1).toStringAsFixed(1), // HDL: 0.8-1.8 mmol/L
        'ldl': (2 + random.nextDouble() * 2).toStringAsFixed(1), // LDL: 2-4 mmol/L
        'vldl': (0.5 + random.nextDouble() * 1).toStringAsFixed(1), // VLDL: 0.5-1.5 mmol/L
        'bmi': (18 + random.nextDouble() * 10).toStringAsFixed(1), // BMI: 18-28
        'status': ['Mắc bệnh', 'Không mắc', 'Có nguy cơ'][random.nextInt(3)], // Trạng thái
      };
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết Quả Chẩn Đoán'),
        backgroundColor: Colors.teal,
      ),
      body: diagnosisHistory.isEmpty
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
                    record['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Ngày khám: ${record['date']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Bệnh án: ${record['disease']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  // Các trường y tế
                  _buildMedicalField('ID', record['id']),
                  _buildMedicalField('Giới tính', record['gender']),
                  _buildMedicalField('Tuổi', record['age'].toString()),
                  _buildMedicalField('Urea', '${record['urea']} mmol/L'),
                  _buildMedicalField('Cr', '${record['cr']} µmol/L'),
                  _buildMedicalField('HbA1c', '${record['hba1c']} %'),
                  _buildMedicalField('Cholesterol', '${record['chol']} mmol/L'),
                  _buildMedicalField('Triglycerides (TG)', '${record['tg']} mmol/L'),
                  _buildMedicalField('HDL', '${record['hdl']} mmol/L'),
                  _buildMedicalField('LDL', '${record['ldl']} mmol/L'),
                  _buildMedicalField('VLDL', '${record['vldl']} mmol/L'),
                  _buildMedicalField('BMI', record['bmi']),
                  SizedBox(height: 10),
                  // Trạng thái
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

  // Hàm tạo hàng hiển thị thông tin y tế
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

  // Hàm lấy màu sắc cho trạng thái
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