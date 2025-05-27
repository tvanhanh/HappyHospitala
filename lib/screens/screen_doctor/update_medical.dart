import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      email: patientData['email'] ?? '',
      examinationDate: patientData['examinationDate'] ?? '',
      examinationTime: patientData['examinationTime'] ?? '',
      doctorName: patientData['doctorName'] ?? '',
      departmentName: patientData['departmentName'] ?? '',
      gender: patientData['gender'] ?? '',
      age: patientData['age'] is String && (patientData['age'] as String).isNotEmpty
          ? int.tryParse(patientData['age'])
          : patientData['age'] as int?,
      urea: patientData['urea'] is String && (patientData['urea'] as String).isNotEmpty
          ? double.tryParse(patientData['urea'])
          : patientData['urea'] as double?,
      creatinine: patientData['creatinine'] is String && (patientData['creatinine'] as String).isNotEmpty
          ? double.tryParse(patientData['creatinine'])
          : patientData['creatinine'] as double?,
      hba1c: patientData['hba1c'] is String && (patientData['hba1c'] as String).isNotEmpty
          ? double.tryParse(patientData['hba1c'])
          : patientData['hba1c'] as double?,
      cholesterol: patientData['cholesterol'] is String && (patientData['cholesterol'] as String).isNotEmpty
          ? double.tryParse(patientData['cholesterol'])
          : patientData['cholesterol'] as double?,
      triglycerides: patientData['triglycerides'] is String && (patientData['triglycerides'] as String).isNotEmpty
          ? double.tryParse(patientData['triglycerides'])
          : patientData['triglycerides'] as double?,
      hdl: patientData['hdl'] is String && (patientData['hdl'] as String).isNotEmpty
          ? double.tryParse(patientData['hdl'])
          : patientData['hdl'] as double?,
      ldl: patientData['ldl'] is String && (patientData['ldl'] as String).isNotEmpty
          ? double.tryParse(patientData['ldl'])
          : patientData['ldl'] as double?,
      vldl: patientData['vldl'] is String && (patientData['vldl'] as String).isNotEmpty
          ? double.tryParse(patientData['vldl'])
          : patientData['vldl'] as double?,
      bmi: patientData['bmi'] is String && (patientData['bmi'] as String).isNotEmpty
          ? double.tryParse(patientData['bmi'])
          : patientData['bmi'] as double?,
      status: patientData['status'] ?? '',
    );
    if (!mounted) return;
    if (success == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm thành công.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
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
                    _buildDateTimeField('Ngày khám', 'examinationDate'),
                    _buildTimeField('Giờ khám', 'examinationTime'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    print('patientData: $patientData');
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
          patientData[key] = value != null && value.isNotEmpty ? int.tryParse(value) : null;
        } else {
          patientData[key] = value != null && value.isNotEmpty ? double.tryParse(value) : null;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Không được để trống';
        }
        if (key == 'age' && int.tryParse(value) == null) {
          return 'Vui lòng nhập số nguyên hợp lệ';
        } else if (key != 'age' && double.tryParse(value) == null) {
          return 'Vui lòng nhập số hợp lệ';
        }
        return null;
      },
    );
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

  Widget _buildDateTimeField(String label, String key) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: patientData[key]?.toString() ?? '',
      ),
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            patientData[key] = dateFormat.format(pickedDate);
          });
        }
      },
      validator: (value) => (value == null || value.isEmpty)
          ? 'Không được để trống'
          : null,
      onSaved: (value) => patientData[key] = value,
    );
  }

  Widget _buildTimeField(String label, String key) {
    final timeFormat = DateFormat('HH:mm');
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        suffixIcon: const Icon(Icons.access_time),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: patientData[key]?.toString() ?? '',
      ),
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          final now = DateTime.now();
          final selectedTime = DateTime(
            now.year,
            now.month,
            now.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          setState(() {
            patientData[key] = timeFormat.format(selectedTime);
          });
        }
      },
      validator: (value) => (value == null || value.isEmpty)
          ? 'Không được để trống'
          : null,
      onSaved: (value) => patientData[key] = value,
    );
  }
}