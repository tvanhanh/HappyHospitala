import 'package:flutter/material.dart';
import '../../services/api_medicalRecord.dart';

class AddPatientForm extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const AddPatientForm({Key? key, this.appointment}) : super(key: key);

  @override
  _AddPatientFormState createState() => _AddPatientFormState();
}

class _AddPatientFormState extends State<AddPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> patientData = {};

  final List<String> genderOptions = ['Nam', 'Nữ'];
  final List<String> statusOptions = ['Mắc', 'Không mắc', 'Nguy cơ mắc'];

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      patientData['id'] = widget.appointment!['id']?.toString() ?? '';
      patientData['patientName'] =
          widget.appointment!['patientName']?.toString() ?? '';
      patientData['departmentName'] =
          widget.appointment!['departmentName']?.toString() ?? '';
      patientData['doctorName'] =
          widget.appointment!['doctorName']?.toString() ?? '';
      patientData['email'] = widget.appointment!['email']?.toString() ?? '';
    }
  }

  Future<void> saveMedicalRecord() async {
    final success = await MedicalRecordService.addMedicalRecord(
      patientName: patientData['patientName'] ?? '',
      email:patientData['email']??'',
      examinationDate: DateTime.now(),
      doctorName: patientData['doctorName'] ?? '',
      departmentName: patientData['departmentName'] ?? '',
      gender: patientData['gender'] ?? '',
      age: patientData['age'] ?? '',
      urea: patientData['urea'] ?? '',
      creatinine: patientData['creatinine'] ?? '',
      hba1c: patientData['hba1c'] ?? '',
      cholesterol: patientData['cholesterol'] ?? '',
      triglycerides: patientData['triglycerides'] ?? '',
      hdl: patientData['hdl'] ?? '',
      ldl: patientData['ldl'] ?? '',
      vldl: patientData['vldl'] ?? '',
      bmi: patientData['bmi'] ?? '',
      status: patientData['status'] ?? '',
    );
    if (!mounted) return;
    if (success == 'true') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm thất bại.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm thành công.')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Thông Tin Bệnh Án'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 3,
                  children: [
                    _buildTextField('ID', 'id', enabled: false),
                    _buildTextField('Tên bệnh nhân', 'patientName',
                        enabled: false),
                    _buildTextField('Email', 'email', enabled: false),
                    _buildDropdown('Giới tính', 'gender', genderOptions),
                    _buildNumberField('Tuổi', 'age'),
                    _buildNumberField('Urea (mmol/L)', 'urea'),
                    _buildNumberField('Cr (µmol/L)', 'creatinine'),
                    _buildNumberField('HbA1c (%)', 'hba1c'),
                    _buildNumberField('Cholesterol (mmol/L)', 'cholesterol'),
                    _buildNumberField(
                        'Triglycerides (TG) (mmol/L)', 'triglycerides'),
                    _buildNumberField('HDL (mmol/L)', 'hdl'),
                    _buildNumberField('LDL (mmol/L)', 'ldl'),
                    _buildNumberField('VLDL (mmol/L)', 'vldl'),
                    _buildNumberField('BMI', 'bmi'),
                    _buildDropdown('Trạng thái', 'status', statusOptions),
                    _buildTextField('Tên khoa', 'departmentName',
                        enabled: false),
                    _buildTextField('Tên bác sĩ', 'doctorName', enabled: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    saveMedicalRecord();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 32.0),
                ),
                child: const Text('Lưu', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool enabled = true}) {
    return TextFormField(
      initialValue: patientData[key]?.toString() ?? '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      enabled: enabled,
      onSaved: (value) => patientData[key] = value,
      validator: (value) => enabled && (value == null || value.isEmpty)
          ? 'Không được để trống'
          : null,
    );
  }

  Widget _buildNumberField(String label, String key) {
    return TextFormField(
        initialValue: patientData[key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        ),
        keyboardType: TextInputType.number,
        onSaved: (value) {
          if (key == 'age') {
            patientData[key] = int.tryParse(value ?? '0');
          } else {
            patientData[key] = double.tryParse(value ?? '0');
          }
        });
  }

  Widget _buildDropdown(String label, String key, List<String> options) {
    return DropdownButtonFormField<String>(
      value: patientData[key] as String? ?? options.first,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: (value) => setState(() => patientData[key] = value),
      validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
    );
  }
}
