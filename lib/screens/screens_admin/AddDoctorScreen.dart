import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_doctors.dart';
import '../../providers/specialty_provider.dart';
import '../../providers/room_provider.dart';
import '../../models/room.dart';

class AddDoctorScreen extends ConsumerStatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  ConsumerState<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends ConsumerState<AddDoctorScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();

  String? selectedSpecialtyId;
  String? selectedRoomId;
  File? _image;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> saveDoctor() async {
    final doctorName = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final specialization = specializationController.text.trim();

    if (doctorName.isEmpty || selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và phòng làm việc")),
      );
      return;
    }

    final roomsList = ref.read(roomProvider(null)).value ?? [];
    final roomObj = roomsList.firstWhere(
      (r) => r.id == selectedRoomId,
      orElse: () => const Room(id: '', roomNumber: '', floor: 1, status: 'Available'),
    );

    final finalSpecialtyId = selectedSpecialtyId ?? roomObj.specialtyId ?? '';

    final avatar = _image?.path ?? "";
    
    final result = await DoctorService.addDoctor(
      doctorName,
      email,
      phone,
      address,
      finalSpecialtyId, // Using specialty as department fallback
      specialization,
      avatar,
      finalSpecialtyId.isNotEmpty ? finalSpecialtyId : null,
      selectedRoomId,
    );

    if (!context.mounted) return;
    if (result == 'success') {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSpecialties = ref.watch(specialtyProvider);
    final asyncRooms = ref.watch(roomProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Bác Sĩ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: _image == null
                  ? const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.camera_alt, size: 30),
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundImage: FileImage(_image!),
                    ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên bác sĩ'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: specializationController,
              decoration: const InputDecoration(labelText: 'Chuyên môn (Ví dụ: Thạc sĩ)'),
            ),
            const SizedBox(height: 16),
            
            // Dropdown Specialty
            asyncSpecialties.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Lỗi tải Chuyên khoa: $err'),
              data: (specialties) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Chuyên Khoa'),
                  value: selectedSpecialtyId,
                  items: specialties.map((spec) {
                    return DropdownMenuItem<String>(
                      value: spec.id,
                      child: Text(spec.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedSpecialtyId = value),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Dropdown Room
            asyncRooms.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Lỗi tải Phòng: $err'),
              data: (rooms) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Phòng Làm Việc'),
                  value: selectedRoomId,
                  items: rooms.map((room) {
                    return DropdownMenuItem<String>(
                      value: room.id,
                      child: Text('Phòng ${room.roomNumber} - Tầng ${room.floor}'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRoomId = value),
                );
              },
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveDoctor,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Lưu Bác Sĩ'),
            )
          ],
        ),
      ),
    );
  }
}
