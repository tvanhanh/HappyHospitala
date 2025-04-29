import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/home_screen.dart';
import '../services/api_appointment.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String patientName = '';
  String phone = '';
  String reason = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _selectTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }

  void _submitBooking() async {
  if (_formKey.currentState!.validate() &&
      selectedDate != null &&
      selectedTime != null) {
    final date =
        '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
    final time = selectedTime!.format(context);

    try {
      final result = await AddAppointments.addAppointment(
        patientName,
        phone,
        reason,
        date,
        time,
      );
      if (!mounted) return;
      if (result=="success") {
        
        showSnackbar("Đặt lịch thành công"); 
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        showSnackbar(result);
      }
    } catch (e) {
      showSnackbar("Lỗi hệ thống: $e");
    }
  } else {
    showSnackbar("Vui lòng nhập đầy đủ thông tin");
  }
}

void showSnackbar(String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.teal,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt lịch khám')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Nhập thông tin để đặt lịch khám',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Họ tên bệnh nhân
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Họ và tên bệnh nhân',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                onChanged: (value) => patientName = value,
              ),
              SizedBox(height: 16),
              // phonephone
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                onChanged: (value) => phone = value,
              ),
              SizedBox(height: 16),

              // Lý do khám
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Lý do khám bệnh',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập lý do' : null,
                onChanged: (value) => reason = value,
              ),
              SizedBox(height: 16),

              // Ngày khám
              ListTile(
                title: Text(selectedDate == null
                    ? 'Chọn ngày khám'
                    : 'Ngày khám: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              Divider(),

              // Giờ khám
              ListTile(
                title: Text(selectedTime == null
                    ? 'Chọn giờ khám'
                    : 'Giờ khám: ${selectedTime!.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: _selectTime,
              ),
              Divider(),

              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitBooking,
                icon: Icon(Icons.check),
                label: Text('Xác nhận đặt lịch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
