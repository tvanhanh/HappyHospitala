import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

const Color kPrimaryColor = Color(0xFF0066FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kCardColor = Colors.white;
const Color kTextDark = Color(0xFF1E293B);

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingAvatar = false;
  String? avatarUrl;
  Map<String, dynamic>? doctorProfile;

  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, dynamic>> educationList = [];
  List<String> certificationsUrls = [];

  @override
  void dispose() {
    _specialtyController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _consultationFeeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ApiService.getDoctorProfile();
      setState(() {
        doctorProfile = profile;
        avatarUrl = profile['avatar'];
        _specialtyController.text = profile['specialty'] ?? '';
        _experienceController.text = (profile['experience_years'] ?? 0).toString();
        _bioController.text = profile['bio'] ?? '';
        _consultationFeeController.text = (profile['consultationFee'] ?? 0).toString();
        _phoneController.text = profile['phoneNumber'] ?? '';
        
        if (profile['education'] != null) {
          educationList = List<Map<String, dynamic>>.from(profile['education']);
        }
        if (profile['certifications_urls'] != null) {
          certificationsUrls = List<String>.from(profile['certifications_urls']);
        }
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải hồ sơ: $e'), backgroundColor: Colors.red),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() => isUploadingAvatar = true);

    try {
      const cloudName = 'dwlikpvh9';
      const uploadPreset = 'asset_clinic';

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await picked.readAsBytes(),
          filename: picked.name,
        ),
      );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final secureUrl = jsonDecode(resBody)['secure_url'] as String?;
        setState(() {
          avatarUrl = secureUrl;
          isUploadingAvatar = false;
        });
      } else {
        throw Exception('Cloudinary upload failed: $resBody');
      }
    } catch (e) {
      setState(() => isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải ảnh thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isSaving = true);
    try {
      final data = {
        "specialty": _specialtyController.text,
        "experience_years": int.tryParse(_experienceController.text) ?? 0,
        "bio": _bioController.text,
        "consultationFee": int.tryParse(_consultationFeeController.text) ?? 0,
        "phoneNumber": _phoneController.text,
        "education": educationList,
        "certifications_urls": certificationsUrls,
        if (avatarUrl != null) "avatar_url": avatarUrl,
      };

      await ApiService.updateDoctorProfile(data);
      
      // Update Shared Preferences immediately so the header and other screens reflect it
      if (avatarUrl != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar', avatarUrl!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công! Chờ Admin duyệt.'), backgroundColor: Colors.green),
      );
      _fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _addEducation() {
    showDialog(
      context: context,
      builder: (context) {
        final degreeCtrl = TextEditingController();
        final universityCtrl = TextEditingController();
        final yearCtrl = TextEditingController();
        return AlertDialog(
          title: const Text("Thêm Bằng cấp / Học vấn"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: degreeCtrl, decoration: const InputDecoration(labelText: "Bằng cấp (VD: Thạc sĩ)")),
              TextField(controller: universityCtrl, decoration: const InputDecoration(labelText: "Trường (VD: ĐH Y Dược)")),
              TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Năm tốt nghiệp")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  educationList.add({
                    "degree": degreeCtrl.text,
                    "university": universityCtrl.text,
                    "year": int.tryParse(yearCtrl.text) ?? DateTime.now().year,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("Thêm"),
            )
          ],
        );
      }
    );
  }

  void _addCertification() {
    showDialog(
      context: context,
      builder: (context) {
        final urlCtrl = TextEditingController();
        return AlertDialog(
          title: const Text("Thêm Chứng chỉ (URL)"),
          content: TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "Đường dẫn URL")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (urlCtrl.text.isNotEmpty) {
                  setState(() => certificationsUrls.add(urlCtrl.text));
                }
                Navigator.pop(context);
              },
              child: const Text("Thêm"),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = doctorProfile?['profile_status'] ?? 'HIDDEN';
    Color statusColor = Colors.grey;
    String statusText = "Đang ẩn";
    if (status == 'ACTIVE') { statusColor = Colors.green; statusText = "Đã duyệt (Active)"; }
    else if (status == 'PENDING_APPROVAL') { statusColor = Colors.orange; statusText = "Chờ duyệt"; }
    else if (status == 'REJECTED') { statusColor = Colors.red; statusText = "Bị từ chối"; }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Hồ sơ Bác sĩ"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor),
                    const SizedBox(width: 10),
                    Text("Trạng thái hồ sơ: $statusText", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- AVATAR UPLOAD SECTION (Premium & Robust Design) ---
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.network(
                                'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    if (isUploadingAvatar)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isUploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (doctorProfile?['fullName'] != null && doctorProfile!['fullName'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    doctorProfile!['fullName'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              _buildSectionTitle("Thông tin chung"),
              _buildTextField(_phoneController, "Số điện thoại", icon: Icons.phone, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_specialtyController, "Chuyên môn sâu (VD: Tim mạch)", icon: Icons.medical_services),
              const SizedBox(height: 12),
              _buildTextField(_experienceController, "Số năm kinh nghiệm", icon: Icons.timer, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_consultationFeeController, "Phí khám (VND)", icon: Icons.attach_money, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_bioController, "Giới thiệu bản thân (Bio)", icon: Icons.description, maxLines: 4),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Học vấn & Bằng cấp"),
                  IconButton(onPressed: _addEducation, icon: const Icon(Icons.add_circle, color: kPrimaryColor)),
                ],
              ),
              ...educationList.asMap().entries.map((e) {
                int idx = e.key;
                var edu = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(edu['degree']),
                    subtitle: Text("${edu['university']} - ${edu['year']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => educationList.removeAt(idx)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Chứng chỉ hành nghề"),
                  IconButton(onPressed: _addCertification, icon: const Icon(Icons.add_circle, color: kPrimaryColor)),
                ],
              ),
              ...certificationsUrls.asMap().entries.map((e) {
                int idx = e.key;
                String url = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.link, color: Colors.blue),
                    title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => certificationsUrls.removeAt(idx)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving ? null : _saveProfile,
                  child: isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Cập nhật & Gửi duyệt", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
