import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Thêm Thư viện Riverpod
import '../../services/api_doctors.dart';
// import '../../services/api_department.dart'; // Bỏ nếu không dùng tới
import '../../services/api_appointment.dart';
import '../providers/specialty_provider.dart';

// Đổi từ StatefulWidget sang ConsumerStatefulWidget để dùng được 'ref'
class AppointmentFormDialog extends ConsumerStatefulWidget {
  const AppointmentFormDialog({super.key});

  @override
  ConsumerState<AppointmentFormDialog> createState() =>
      _AppointmentFormDialogState();
}

// Kế thừa từ ConsumerState thay vì State thông thường
class _AppointmentFormDialogState extends ConsumerState<AppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  /// Patient
  final patientNameController = TextEditingController();
  final phoneController = TextEditingController();
  final cccdController = TextEditingController();
  final addressController = TextEditingController();
  final reasonController = TextEditingController();

  /// Date
  final birthController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  String? gender;

  List<dynamic> departments = [];
  List<dynamic> doctors = [];

  String? selectedDepartmentId;
  String? selectedDoctorId;

  bool loadingDepartments = true;
  bool loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    // Gọi hàm load dữ liệu chuyên khoa từ Provider khi khởi tạo popup
    loadSpeciality(); 
  }

  @override
  void dispose() {
    patientNameController.dispose();
    phoneController.dispose();
    cccdController.dispose();
    addressController.dispose();
    reasonController.dispose();
    birthController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  // ĐÃ SỬA: Sắp xếp gọn gàng logic nạp dữ liệu chuyên khoa từ Riverpod
  Future<void> loadSpeciality() async {
    try {
      final result = await ref.read(specialtyProvider.future);
      setState(() {
        departments = result; 
        loadingDepartments = false;
      });
    } catch (e) {
      debugPrint("Lỗi load chuyên khoa: ${e.toString()}");
      setState(() {
        loadingDepartments = false;
      });
    }
  }

  Future<void> loadDoctors(String departmentId) async {
    print("loadDoctors: $departmentId");
    setState(() {
      loadingDoctors = true;
      doctors = []; // Xóa danh sách bác sĩ cũ trước khi nạp mới
      selectedDoctorId = null;
    });

    try {
      final result = await DoctorService.getDoctorsBySpecialty(departmentId);
      print("Doctors result: $result");
      setState(() {
        doctors = result ?? [];
        loadingDoctors = false;
      });
    } catch (e) {
      print("ERROR load bác sĩ: $e");
      setState(() {
        loadingDoctors = false;
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDoctorId == null ||
        selectedDepartmentId == null ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn đầy đủ bác sĩ, ngày và giờ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final birthParts = birthController.text.split("/");
      final formattedBirth =
          "${birthParts[2]}-${birthParts[1]}-${birthParts[0]}";

      final result = await AppointmentApi.addAppointment(
        doctorId: selectedDoctorId!,
        departmentId: selectedDepartmentId!,
        patientName: patientNameController.text,
        phone: phoneController.text,
        cccd: cccdController.text,
        birthDate: formattedBirth,
        gender: gender,
        address: addressController.text,
        reason: reasonController.text,
        date: dateController.text,
        time: timeController.text,
      );
      
      if (!mounted) return;
      print("Kết quả thêm lịch hẹn: $result"); 

      if (result is Map && result["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đặt lịch thành công 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Đóng và báo thành công về màn hình chính
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Thất bại: ${result is Map ? result["message"] : result}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi hệ thống: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 750,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Đặt lịch khám mới",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Thông tin bệnh nhân",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: patientNameController,
                          label: "Tên bệnh nhân",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          controller: phoneController,
                          label: "Số điện thoại",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: cccdController,
                          label: "CCCD",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration: const InputDecoration(
                            labelText: "Giới tính",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Nam", child: Text("Nam")),
                            DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              gender = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: birthController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Ngày sinh",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.cake),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                birthController.text =
                                    "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          controller: addressController,
                          label: "Địa chỉ",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    "Thông tin lịch khám",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // DROPDOWN CHUYÊN KHOA
                      Expanded(
  child: DropdownButtonFormField<String>(
    value: selectedDepartmentId,
    decoration: InputDecoration(
      labelText: loadingDepartments ? "Đang tải chuyên khoa..." : "Chuyên khoa",
      border: const OutlineInputBorder(),
    ),
    items: departments.map((department) {
      // Đọc linh hoạt từ Map hoặc Object model
      final id = department is Map ? department["id"] : department.id;
      final name = department is Map ? department["departmentName"] : department.name;
      
      return DropdownMenuItem<String>(
        // SỬA TẠI ĐÂY: Dùng đúng biến id và name vừa lấy ở trên
        value: id?.toString(),
        child: Text(name?.toString() ?? "Không rõ tên khoa"),
      );
    }).toList(),
    onChanged: loadingDepartments ? null : (value) async {
      print("Đã chọn khoa: $value");
      setState(() {
        selectedDepartmentId = value;
      });
      if (value != null) {
        await loadDoctors(value);
      }
    },
  ),
),
                      const SizedBox(width: 15),
                      // DROPDOWN BÁC SĨ
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedDoctorId,
                          decoration: InputDecoration(
                            labelText: loadingDoctors ? "Đang tải danh sách..." : "Bác sĩ",
                            border: const OutlineInputBorder(),
                          ),
                          items: doctors.map((doctor) {
                            return DropdownMenuItem<String>(
                             value: doctor.id?.toString() ?? doctor.sId?.toString(), 
        child: Text(doctor.name?.toString() ?? "Không rõ tên"),             
                            );
                          }).toList(),
                          onChanged: doctors.isEmpty ? null : (value) {
                            setState(() {
                              selectedDoctorId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Ngày khám",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                dateController.text =
                                    "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: timeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Giờ khám",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                timeController.text = pickedTime.format(context);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Lý do khám",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Hủy"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Lưu lịch hẹn"),
                        onPressed: () async {
                          // ĐÃ SỬA: Xóa bỏ Navigator.pop() thừa để nút submit thực thi lưu và kiểm tra API trước
                          await submit();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Không được để trống";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}