import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/patient_management.dart';
import 'package:flutter_application_datlichkham/models/medical_record.dart';
import '../../models/patient.dart';

class MedicalRecordPage extends StatefulWidget {
  final Patient patient;

  MedicalRecordPage({required this.patient});

  @override
  _MedicalRecordPageState createState() => _MedicalRecordPageState();
}

class _MedicalRecordPageState extends State<MedicalRecordPage> {
  // Dữ liệu giả lập cho bệnh án (bệnh tiểu đường)
  MedicalRecord record = MedicalRecord(
    patientId: "BN-56301",
    diagnosis: "Tiểu đường",
    urea: 5.2,
    cr: 1.1,
    hba1c: 7.5,
    chol: 200,
    tg: 150,
    hdl: 40,
    ldl: 130,
    vldl: 30,
    bmi: 27.5,
    status: "Mắc bệnh",
    doctorNote: "Cần theo dõi đường huyết thường xuyên", // Thêm giá trị cho doctorNote
    date: DateTime.now(),
  );

  void _editRecord(BuildContext context) {
    final _ureaCtrl = TextEditingController(text: record.urea.toString());
    final _crCtrl = TextEditingController(text: record.cr.toString());
    final _hba1cCtrl = TextEditingController(text: record.hba1c.toString());
    final _cholCtrl = TextEditingController(text: record.chol.toString());
    final _tgCtrl = TextEditingController(text: record.tg.toString());
    final _hdlCtrl = TextEditingController(text: record.hdl.toString());
    final _ldlCtrl = TextEditingController(text: record.ldl.toString());
    final _vldlCtrl = TextEditingController(text: record.vldl.toString());
    final _bmiCtrl = TextEditingController(text: record.bmi.toString());
    final _doctorNoteCtrl = TextEditingController(text: record.doctorNote); // Thêm controller cho doctorNote
    String _status = record.status;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa Hồ Sơ Bệnh Án'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _ureaCtrl,
                decoration: InputDecoration(labelText: 'Urea'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _crCtrl,
                decoration: InputDecoration(labelText: 'Cr'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _hba1cCtrl,
                decoration: InputDecoration(labelText: 'HbA1c'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _cholCtrl,
                decoration: InputDecoration(labelText: 'Chol'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _tgCtrl,
                decoration: InputDecoration(labelText: 'TG'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _hdlCtrl,
                decoration: InputDecoration(labelText: 'HDL'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _ldlCtrl,
                decoration: InputDecoration(labelText: 'LDL'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _vldlCtrl,
                decoration: InputDecoration(labelText: 'VLDL'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bmiCtrl,
                decoration: InputDecoration(labelText: 'BMI'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _doctorNoteCtrl,
                decoration: InputDecoration(labelText: 'Ghi chú bác sĩ'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: 'Trạng thái'),
                items: ['Mắc bệnh', 'Không mắc', 'Có nguy cơ']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (val) {
                  _status = val!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                record = MedicalRecord(
                  patientId: record.patientId,
                  diagnosis: record.diagnosis,
                  urea: double.parse(_ureaCtrl.text),
                  cr: double.parse(_crCtrl.text),
                  hba1c: double.parse(_hba1cCtrl.text),
                  chol: double.parse(_cholCtrl.text),
                  tg: double.parse(_tgCtrl.text),
                  hdl: double.parse(_hdlCtrl.text),
                  ldl: double.parse(_ldlCtrl.text),
                  vldl: double.parse(_vldlCtrl.text),
                  bmi: double.parse(_bmiCtrl.text),
                  status: _status,
                  doctorNote: _doctorNoteCtrl.text, // Cập nhật doctorNote
                  date: DateTime.now(),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã cập nhật bệnh án')),
              );
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản Lý Bệnh Án'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editRecord(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Thông tin bệnh nhân
            Text(
              'Thông Tin Bệnh Nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.badge),
              title: Text('ID: ${widget.patient.medicalId}'),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Tên: ${widget.patient.name}'),
            ),
            ListTile(
              leading: Icon(Icons.accessibility),
              title: Text('Giới tính: ${widget.patient.gender}'),
            ),
            ListTile(
              leading: Icon(Icons.cake),
              title: Text('Tuổi: ${widget.patient.age}'),
            ),
            Divider(),
            // Thông tin bệnh án
            Text(
              'Thông Tin Bệnh Án (Tiểu đường)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Chẩn đoán: ${record.diagnosis}'),
            ),
            ListTile(
              leading: Icon(Icons.opacity),
              title: Text('Urea: ${record.urea} mmol/L'),
            ),
            ListTile(
              leading: Icon(Icons.opacity),
              title: Text('Cr: ${record.cr} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.bloodtype),
              title: Text('HbA1c: ${record.hba1c}%'),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Chol: ${record.chol} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('TG: ${record.tg} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('HDL: ${record.hdl} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('LDL: ${record.ldl} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('VLDL: ${record.vldl} mg/dL'),
            ),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('BMI: ${record.bmi} kg/m²'),
            ),
            ListTile(
              leading: Icon(Icons.health_and_safety),
              title: Text('Trạng thái: ${record.status}'),
            ),
            ListTile(
              leading: Icon(Icons.note),
              title: Text('Ghi chú bác sĩ: ${record.doctorNote}'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Ngày cập nhật: ${record.date.day}/${record.date.month}/${record.date.year}'),
            ),
          ],
        ),
      ),
    );
  }
}