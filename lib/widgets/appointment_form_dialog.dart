import 'package:flutter/material.dart';
import '../../services/api_doctors.dart';
import '../../services/api_department.dart';
import '../../services/api_appointment.dart';
class AppointmentFormDialog extends StatefulWidget {
  const AppointmentFormDialog({super.key});

  @override
  State<AppointmentFormDialog> createState() =>
      _AppointmentFormDialogState();
}

class _AppointmentFormDialogState
    extends State<AppointmentFormDialog> {
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
    loadDepartments();
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

  Future<void> loadDepartments() async {
    try {
      final result =
          await DepartmentService.getDepartments();

      setState(() {
        departments = result;
        loadingDepartments = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loadingDepartments = false;
      });
    }
  }

  Future<void> loadDoctors(String departmentId) async {
  print("loadDoctors: $departmentId");

  try {
    final result =
        await DoctorService.getDoctorsByDepartment(
            departmentId);

    print("Doctors result:");
    print(result);

    setState(() {
      doctors = result;
    });
  } catch (e) {
    print("ERROR: $e");
  }
}
 Future<void> submit() async {
  if (!_formKey.currentState!.validate()) return;

  // check bắt buộc
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
    print(result); 
    if (result is Map && result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đặt lịch thành công 🎉"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
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
        content: Text("Lỗi: $e"),
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
                crossAxisAlignment:
               
                    CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Đặt lịch khám mới",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Thông tin bệnh nhân",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller:
                              patientNameController,
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
                        child:
                            DropdownButtonFormField<
                                String>(
                          value: gender,
                          decoration:
                              const InputDecoration(
                            labelText: "Giới tính",
                            border:
                                OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Nam",
                              child: Text("Nam"),
                            ),
                            DropdownMenuItem(
                              value: "Nữ",
                              child: Text("Nữ"),
                            ),
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
                          decoration:
                              const InputDecoration(
                            labelText: "Ngày sinh",
                            border:
                                OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.cake),
                          ),
                          onTap: () async {
                            final picked =
                                await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime(2000),
                              firstDate:
                                  DateTime(1900),
                              lastDate:
                                  DateTime.now(),
                            );

                            if (picked != null) {
                              birthController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: _buildTextField(
                          controller:
                              addressController,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child:
                            DropdownButtonFormField<
                                String>(
                          value: selectedDepartmentId,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Chuyên khoa",
                            border:
                                OutlineInputBorder(),
                          ),
                          items: departments
                              .map((department) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  department["id"],
                              child: Text(
                                department[
                                    "departmentName"],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                           print("Đã chọn khoa: $value");
                            setState(() {
                              selectedDepartmentId = value;
                            });
                            if (value != null) {
                              await loadDoctors(
                                  value);
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child:
                            DropdownButtonFormField<
                                String>(
                          value:
                              selectedDoctorId,
                          decoration:
                              const InputDecoration(
                            labelText: "Bác sĩ",
                            border:
                                OutlineInputBorder(),
                          ),
                          items: doctors
                              .map((doctor) {
                            return DropdownMenuItem<
                                String>(
                              value:doctor["_id"],
                              child: Text(
                                doctor[
                                    "name"],
                              ),
                            );
                          }).toList(),
                          onChanged:
                              doctors.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        selectedDoctorId =
                                            value;
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
                          controller:
                              dateController,
                          readOnly: true,
                          decoration:
                              const InputDecoration(
                            labelText: "Ngày khám",
                            border:
                                OutlineInputBorder(),
                            prefixIcon: Icon(
                                Icons
                                    .calendar_today),
                          ),
                          onTap: () async {
                            final pickedDate =
                                await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now(),
                              firstDate:
                                  DateTime.now(),
                              lastDate:
                                  DateTime(2035),
                            );

                            if (pickedDate !=
                                null) {
                              dateController.text =
                                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: TextFormField(
                          controller:
                              timeController,
                          readOnly: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Giờ khám",
                            border:
                                OutlineInputBorder(),
                            prefixIcon: Icon(
                                Icons
                                    .access_time),
                          ),
                          onTap: () async {
                            final pickedTime =
                                await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.now(),
                            );

                            if (pickedTime !=
                                null) {
                              timeController.text =
                                  pickedTime.format(
                                      context);
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
                    decoration:
                        const InputDecoration(
                      labelText: "Lý do khám",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                              context);
                        },
                        child: const Text(
                            "Hủy"),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        icon:
                            const Icon(Icons.save),
                        label: const Text(
                            "Lưu lịch hẹn"),
                        onPressed: () async {
                           if (!_formKey.currentState!.validate()) return;
                            await submit(); 
                          debugPrint("Patient: ${patientNameController.text}");
                          debugPrint("Doctor: $selectedDoctorId");

                          Navigator.pop(
                              context);
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
        if (value == null ||
            value.trim().isEmpty) {
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