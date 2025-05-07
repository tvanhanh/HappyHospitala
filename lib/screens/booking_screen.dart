import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/home_screen.dart';
import '../services/api_appointment.dart';
import '../services/api_department.dart';
import '../services/api_doctors.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> doctors = [];
  String? selectedDepartmentId;
  String? selectedDoctorId;
  final _formKey = GlobalKey<FormState>();
  String patientName = '';
  String phone = '';
  String reason = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final data = await DepartmentService.getDepartments();
      setState(() {
        departments = data;
      });
    } catch (e) {
      showSnackbar('Lỗi khi lấy danh sách phòng ban: $e');
    }
  }

  Future<void> fetchDoctors(String departmentId) async {
    try {
    final data = await DoctorService.getDoctors();
    print('Danh sách bác sĩ gốc: $data');
    // Khai báo biến filteredDoctors
    final filteredDoctors = data
        .where((doctor) => doctor['departmentId'] == departmentId)
        .toList();
    print('Danh sách bác sĩ sau khi lọc cho departmentId $departmentId: $filteredDoctors');
    setState(() {
      doctors = filteredDoctors; // Sử dụng filteredDoctors đã khai báo
      selectedDoctorId = null;
      if (doctors.isEmpty) {
        showSnackbar('Không có bác sĩ trong phòng ban này');
      }
    });
  } catch (e) {
    showSnackbar('Lỗi khi lấy danh sách bác sĩ: $e');
  }
  }

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
        selectedTime != null &&
        selectedDepartmentId != null &&
        selectedDoctorId != null) {
          
      final date =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      final time = selectedTime!.format(context);

      print('selectedDepartmentId: $selectedDepartmentId');
      print('selectedDoctorId: $selectedDoctorId');
      print('date: $date');
      print('time: $time');

      try {
        final result = await AddAppointments.addAppointment(
          patientName,
          phone,
          reason,
          date,
          time,
          selectedDepartmentId!,
          selectedDoctorId!,
        );
        if (!mounted) return;
        if (result == "success") {
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
              // Phòng ban
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Chọn phòng ban',
                  border: OutlineInputBorder(),
                ),
                value: selectedDepartmentId,
                items: departments.map((dept) {
                  return DropdownMenuItem<String>(
                    value: dept['id'],
                    child: Text(
                        dept['departmentName'] ?? 'Không rõ tên phòng ban'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartmentId = value;
                    doctors = []; // Reset danh sách bác sĩ
                    if (value != null) {
                      fetchDoctors(
                          value); // Lấy danh sách bác sĩ theo phòng ban
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn phòng ban' : null,
              ),
              SizedBox(height: 16),

// Bác sĩ
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Chọn bác sĩ',
                  border: OutlineInputBorder(),
                ),
                value: selectedDoctorId,
                items: doctors.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor['id'],
                    child: Text(doctor['doctorName'] ?? 'Không rõ tên bác sĩ'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDoctorId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn bác sĩ' : null,
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
