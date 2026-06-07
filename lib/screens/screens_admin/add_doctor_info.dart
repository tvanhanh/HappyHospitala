import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_doctors.dart';

import 'package:flutter_application_datlichkham/services/api_department.dart';

class AddDoctorInfoScreen extends StatefulWidget {
  final String doctorId;

  const AddDoctorInfoScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<AddDoctorInfoScreen> createState() => _AddDoctorInfoScreenState();
}

class _AddDoctorInfoScreenState extends State<AddDoctorInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final phoneController = TextEditingController();
  final experienceController = TextEditingController();
  final degreeController = TextEditingController();
  final descriptionController = TextEditingController();
  final clinicAddressController = TextEditingController();
  final priceController = TextEditingController();
  final avatarController = TextEditingController();

  String? specialty;
  String? workShift;

  List<dynamic> departments = [];

  Map<String, dynamic>? doctor;

  bool isLoading = false;
  bool isFetching = true;

  bool loadingDepartments = true;
  String? selectedDepartmentId;

  final List<String> specialties = [
    "Da liễu",
    "Tim mạch",
    "Nội tổng quát",
    "Nhi khoa",
    "Thần kinh",
    "Xương khớp",
    "Mắt",
  ];

  final List<String> shifts = [
    "Sáng (08:00 - 12:00)",
    "Chiều (13:00 - 17:00)",
    "Tối (17:00 - 21:00)",
    "Full time",
  ];

  @override
  void initState() {
    super.initState();
    loadDepartments();
    loadDoctor();
  }

  Future<void> loadDepartments() async {
    try {
      final result = await DepartmentService.getDepartments();

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

  Future<void> loadDoctor() async {
    final res = await DoctorService.getDoctorById(widget.doctorId);

    if (res == null) {
      setState(() => isFetching = false);
      return;
    }

    final profile = res['profile'] ?? {};

    setState(() {
      doctor = res;

      phoneController.text = profile['phone']?.toString() ?? "";
      experienceController.text = profile['experience']?.toString() ?? "";
      degreeController.text = profile['degree']?.toString() ?? "";
      descriptionController.text = profile['description']?.toString() ?? "";
      clinicAddressController.text = profile['clinicAddress']?.toString() ?? "";
      priceController.text = profile['price']?.toString() ?? "";
      avatarController.text = profile['avatar']?.toString() ?? "";
      specialty = profile['specialty'];
      workShift = profile['workShift'];

      selectedDepartmentId = res['departmentId']?.toString();
      isFetching = false; // ⭐ QUAN TRỌNG
    });
  }

  // ================= SUBMIT =================
  void submitDoctorInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      "avatar": avatarController.text.trim(),
      "phone": phoneController.text,
      "specialty": specialty,
      "departmentId": selectedDepartmentId,
      "experience": experienceController.text,
      "degree": degreeController.text,
      "description": descriptionController.text,
      "workShift": workShift,
      "clinicAddress": clinicAddressController.text,
      "price": priceController.text,
    };

    try {
      await DoctorService.updateDoctorInfo(widget.doctorId, data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật bác sĩ thành công"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Cập nhật hồ sơ bác sĩ"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatarController.text.trim().isNotEmpty
                    ? NetworkImage(
                        "${avatarController.text.trim()}?v=${DateTime.now().millisecondsSinceEpoch}",
                      )
                    : null,
                child: avatarController.text.trim().isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),

              const SizedBox(height: 20),
              _buildField("Ảnh đại diện", avatarController, Icons.image),

              _buildField("Số điện thoại", phoneController, Icons.phone),

              _buildDropdown("Chuyên khoa", specialty, specialties,
                  (v) => setState(() => specialty = v)),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: selectedDepartmentId,
                  decoration: InputDecoration(
                    labelText: "Khoa",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng chọn khoa";
                    }
                    return null;
                  },
                  items: departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department["id"].toString(),
                      child: Text(
                        department["departmentName"],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartmentId = value;
                    });
                  },
                ),
              ),
              _buildDropdown("Ca làm việc", workShift, shifts,
                  (v) => setState(() => workShift = v)),

              _buildField(
                  "Kinh nghiệm (năm)", experienceController, Icons.work),

              _buildField("Bằng cấp", degreeController, Icons.school),

              //_buildField("Địa chỉ phòng khám", clinicAddressController,
              //   Icons.location_on),

              _buildField(
                  "Mô tả chuyên môn", descriptionController, Icons.description,
                  maxLines: 4),

              _buildField("Giá khám (VNĐ)", priceController, Icons.payments),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitDoctorInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Lưu thay đổi"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= FIELD =================
  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Không được để trống" : null,
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    experienceController.dispose();
    degreeController.dispose();
    descriptionController.dispose();
    clinicAddressController.dispose();
    priceController.dispose();
    avatarController.dispose();
    super.dispose();
  }
}
