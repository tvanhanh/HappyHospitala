import 'package:flutter/material.dart';
import './patient_detail.dart';

class PatientListScreen extends StatelessWidget {
  final List<Map<String, String>> patients = [
    {
      'name': 'Nguyễn Văn A',
      'dob': '12/05/1985',
      'gender': 'Nam',
      'phone': '0901234567',
      'address': '123 Lê Lợi, Q1, TP.HCM'
    },
    {
      'name': 'Trần Thị B',
      'dob': '25/11/1990',
      'gender': 'Nữ',
      'phone': '0912345678',
      'address': '456 Hai Bà Trưng, Q3, TP.HCM'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách bệnh nhân')),
      
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(patient['name'] ?? ''),
              subtitle: Text("SĐT: ${patient['phone']}"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientDetailScreen(patient: patient),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
