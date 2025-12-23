import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/patient_management.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import '../../services/api_appointment.dart';
import '../../services/api_department.dart';
import '../../services/api_doctors.dart';
import 'package:intl/intl.dart'; // Import để format ngày tháng

// --- PALETTE MÀU SẮC ---
const Color kPrimaryColor = Color.fromARGB(255, 19, 137, 211); // blue
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kInputFillColor = Colors.white;

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- LOGIC VÀ BIẾN STATE (GIỮ NGUYÊN) ---
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
      showSnackbar('Lỗi khi lấy danh sách phòng ban: $e', isError: true);
    }
  }

  Future<void> fetchDoctors(String departmentId) async {
    try {
      final data = await DoctorService.getDoctors();
      final filteredDoctors = data
          .where((doctor) => doctor['departmentId'] == departmentId)
          .toList();
      setState(() {
        doctors = filteredDoctors;
        selectedDoctorId = null;
        if (doctors.isEmpty) {
          showSnackbar('Không có bác sĩ trong phòng ban này', isError: true);
        }
      });
    } catch (e) {
      showSnackbar('Lỗi khi lấy danh sách bác sĩ: $e', isError: true);
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

      try {
        final selectedDepartment = departments.firstWhere(
          (dept) => dept['id'] == selectedDepartmentId,
          orElse: () => {},
        );
        final selectedDoctor = doctors.firstWhere(
          (doc) => doc['id'] == selectedDoctorId,
          orElse: () => {},
        );
        final departmentName = selectedDepartment['departmentName'] ?? '';
        final doctorName = selectedDoctor['doctorName'] ?? '';
        final result = await AddAppointments.addAppointment(
          patientName,
          phone,
          reason,
          date,
          time,
          departmentName,
          doctorName,
        );

        if (result == "Đặt lịch thành công") {
          if (!mounted) return;
          showSnackbar("Đặt lịch thành công");
          Future.delayed(Duration(seconds: 1), () {
            if (!mounted) return;
            context.go('/home');
          });
        } else {
          showSnackbar(result, isError: true);
        }
      } catch (e) {
        showSnackbar("Lỗi hệ thống: $e", isError: true);
      }
    } else {
      showSnackbar("Vui lòng nhập đầy đủ thông tin", isError: true);
    }
  }

  void showSnackbar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  // --- HẾT LOGIC VÀ BIẾN STATE ---

  // --- 🔥 PHẦN GIAO DIỆN (UI) ĐÃ LÀM ĐẸP ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Đặt Lịch Khám Bệnh',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điền thông tin và chọn thời gian khám',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
              SizedBox(height: 20),

              // --- 1. THÔNG TIN CÁ NHÂN ---
              _buildSectionTitle("Thông Tin Bệnh Nhân"),
              _buildTextField('Họ và tên bệnh nhân', Icons.person,
                  (value) => patientName = value!),
              SizedBox(height: 16),
              _buildTextField(
                  'Số điện thoại', Icons.phone, (value) => phone = value!),
              SizedBox(height: 16),

              // Lý do khám
              TextFormField(
                decoration: _buildInputDecoration(
                    labelText: 'Lý do khám bệnh', icon: Icons.sick),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập lý do' : null,
                onChanged: (value) => reason = value,
              ),
              SizedBox(height: 30),

              // --- 2. THÔNG TIN LỊCH HẸN VÀ BÁC SĨ ---
              _buildSectionTitle("Chọn Lịch Hẹn"),

              // Dropdown Phòng ban
              _buildDropdown(
                label: 'Chọn phòng ban',
                icon: Icons.apartment,
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
                    doctors = [];
                    if (value != null) {
                      fetchDoctors(value);
                    }
                  });
                },
                validator: 'Vui lòng chọn phòng ban',
              ),
              SizedBox(height: 16),

              // Dropdown Bác sĩ
              _buildDropdown(
                label: 'Chọn bác sĩ',
                icon: Icons.medical_services,
                value: selectedDoctorId,
                items: doctors.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor['id'],
                    child: Text(doctor['doctorName'] ?? 'Không rõ tên bác sĩ'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedDoctorId = value),
                validator: 'Vui lòng chọn bác sĩ',
              ),
              SizedBox(height: 25),

              // Ngày khám
              _buildDateTimeTile(
                title: 'Ngày khám',
                icon: Icons.calendar_today,
                value: selectedDate == null
                    ? null
                    : DateFormat('dd/MM/yyyy').format(selectedDate!),
                onTap: _selectDate,
                isFilled: selectedDate != null,
              ),
              SizedBox(height: 10),

              // Giờ khám
              _buildDateTimeTile(
                title: 'Giờ khám',
                icon: Icons.access_time_filled,
                value:
                    selectedTime == null ? null : selectedTime!.format(context),
                onTap: _selectTime,
                isFilled: selectedTime != null,
              ),

              SizedBox(height: 40),

              // --- 3. NÚT XÁC NHẬN ĐẶT LỊCH ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitBooking,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('XÁC NHẬN ĐẶT LỊCH',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CON CHO UI ĐẸP ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
            letterSpacing: 1.0),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: kInputFillColor,
      // Đảm bảo style đồng bộ
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 2)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, Function(String) onChanged) {
    return TextFormField(
      decoration: _buildInputDecoration(labelText: label, icon: icon),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập $label' : null,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown(
      {required String label,
      required IconData icon,
      required String? value,
      required List<DropdownMenuItem<String>> items,
      required Function(String?) onChanged,
      required String validator}) {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration(labelText: label, icon: icon),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? validator : null,
    );
  }

  Widget _buildDateTimeTile(
      {required String title,
      required IconData icon,
      String? value,
      required VoidCallback onTap,
      required bool isFilled}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: kInputFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isFilled ? kPrimaryColor : Colors.grey.shade300,
              width: isFilled ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: isFilled ? kPrimaryColor : Colors.grey.shade600),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                value ?? title,
                style: TextStyle(
                    fontSize: 16,
                    color: isFilled ? kTextPrimary : Colors.grey.shade600,
                    fontWeight: isFilled ? FontWeight.w500 : FontWeight.normal),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
