import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../services/api_service.dart';
import '../../services/api_doctors.dart';
import '../../services/api_appointment.dart';
import 'package:flutter/foundation.dart';

XFile? imageFile;
Uint8List? imageBytes;

const Color kPrimary = Color(0xFF1389D3);
const Color kBg = Color(0xFFF5F7FA);

class BookingScreen extends StatefulWidget {
  final String doctorId;

  const BookingScreen({super.key, required this.doctorId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  String patientName = '';
  String phone = '';
  String gender = '';
  String address = '';
  String medicalHistory = '';
  String allergies = '';

  // booking
  String reason = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // doctor
  Map<String, dynamic>? doctor;
  bool loading = true;

  XFile? imageFile; // global
  Uint8List? imageBytes;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([loadProfile(), loadDoctor()]);
  }

  Future<void> loadProfile() async {
    final res = await ApiService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString("name") ?? '';

    final p = res['profile'] ?? {};

    setState(() {
      patientName = name;
      phone = p['phone'] ?? '';
      gender = p['gender'] ?? '';
      address = p['address'] ?? '';
      medicalHistory = p['medicalHistory'] ?? '';
      allergies = p['allergies'] ?? '';
    });
  }

  Future<void> loadDoctor() async {
    final data = await DoctorService.getDoctorById(widget.doctorId);
    setState(() {
      doctor = data;
      loading = false;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        imageFile = picked;
        imageBytes = bytes;
      });
    }
  }

  // ================= UPLOAD CLOUDINARY =================
  Future<String?> uploadToCloudinary(XFile file) async {
    const cloudName = "dwlikpvh9";
    const uploadPreset = "asset_clinic";

    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  // ================= PICK DATE =================
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ================= PICK TIME =================
  void pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ngày và giờ")),
      );
      return;
    }

    try {
      // upload image nếu có
      if (imageFile != null) {
        imageUrl = await uploadToCloudinary(imageFile!);
      }

      final date = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final time = selectedTime!.format(context);

      final result = await AppointmentApi.addAppointment(
        doctorId: doctor!['_id'],
        patientName: patientName,
        phone: phone,
        gender: gender,
        address: address,
        medicalHistory: medicalHistory,
        allergies: allergies,
        reason: reason,
        date: date,
        time: time,
        imageUrl: imageUrl,
      );

      // ================= SUCCESS =================
      if (result.toLowerCase().contains("success") ||
          result.toLowerCase().contains("thành công")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đặt lịch thành công 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        // optional: quay về màn trước
        Navigator.pop(context);
      }
      // ================= FAIL =================
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thất bại: $result"),
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
    final doctorName = doctor?['name'] ?? '';
    final doctorAvatar =
        doctor?['profile']?['avatar'] ?? doctor?['avatar'] ?? '';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text("Đặt lịch khám"),
        backgroundColor: kPrimary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // DOCTOR
                    _cardDoctor(doctorName, doctorAvatar),

                    const SizedBox(height: 20),

                    // PROFILE AUTO
                    _cardProfile(),

                    const SizedBox(height: 20),

                    // REASON
                    TextFormField(
                      decoration: _input("Lý do khám"),
                      onChanged: (v) => reason = v,
                    ),

                    const SizedBox(height: 15),

                    // IMAGE UPLOAD
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imageFile == null
                            ? const Center(child: Text("Thêm ảnh bệnh"))
                            : imageBytes == null
                                ? const Center(child: Text("Thêm ảnh bệnh"))
                                : Image.memory(imageBytes!, fit: BoxFit.cover),
                      ),
                    ),

                    const SizedBox(height: 15),

                    _box(
                      "Chọn ngày",
                      Icons.date_range,
                      pickDate,
                      value: selectedDate == null
                          ? null
                          : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    ),
                    _box(
                      "Chọn giờ",
                      Icons.access_time,
                      pickTime,
                      value: selectedTime == null
                          ? null
                          : selectedTime!.format(context),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
                        child: const Text("Đặt lịch"),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cardDoctor(String name, String avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // ================= AVATAR =================
          CircleAvatar(
            radius: 25,
            backgroundImage:
                (avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),

          const SizedBox(width: 12),

          // ================= TEXT =================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Đã chọn bác sĩ",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardProfile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TITLE =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Thông tin cá nhân",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // EDIT BUTTON
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _showEditProfileDialog();
                },
              )
            ],
          ),

          const Divider(),

          // ================= NAME =================
          Text(
            "👤 $patientName",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text("📞 SĐT: $phone"),
          Text("🚻 Giới tính: $gender"),
          Text("🏠 Địa chỉ: $address"),
          Text("🧾 Tiền sử bệnh: $medicalHistory"),
          Text("⚠️ Dị ứng: $allergies"),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: patientName);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    final medicalController = TextEditingController(text: medicalHistory);
    final allergyController = TextEditingController(text: allergies);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chỉnh sửa thông tin"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Họ tên"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Địa chỉ"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: medicalController,
                  decoration: const InputDecoration(labelText: "Tiền sử bệnh"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allergyController,
                  decoration: const InputDecoration(labelText: "Dị ứng"),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Huỷ"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Lưu"),
              onPressed: () {
                setState(() {
                  patientName = nameController.text;
                  phone = phoneController.text;
                  address = addressController.text;
                  medicalHistory = medicalController.text;
                  allergies = allergyController.text;
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _box(String title, IconData icon, VoidCallback onTap,
      {String? value}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(value ?? title),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
