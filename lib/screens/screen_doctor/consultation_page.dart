import 'package:flutter/material.dart';

class ConsultationPage extends StatefulWidget {
  @override
  _ConsultationPageState createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _consultationController = TextEditingController();

  void _sendConsultation() {
    String name = _patientNameController.text.trim();
    String content = _consultationController.text.trim();

    if (name.isNotEmpty && content.isNotEmpty) {
      // Xử lý gửi tư vấn (có thể tích hợp API)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi tư vấn đến $name')),
      );
      _patientNameController.clear();
      _consultationController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gửi Tư Vấn Cho Bệnh Nhân'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _patientNameController,
              decoration: InputDecoration(
                labelText: 'Tên bệnh nhân',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _consultationController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Nội dung tư vấn',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text('Gửi tư vấn'),
              onPressed: _sendConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
