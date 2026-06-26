import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/patient_provider.dart';

class PatientManagementScreen extends ConsumerStatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  ConsumerState<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends ConsumerState<PatientManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color kPrimaryColor = Color(0xFF0D47A1);
  static const Color kSecondaryColor = Color(0xFF1976D2);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncPatients = ref.watch(patientProvider(_searchQuery));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "HappyClinic - Hệ thống quản lý",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Bệnh nhân", // Set correct selected menu
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý bệnh nhân',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar Input
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo Tên, SĐT hoặc số CCCD...',
                        prefixIcon: const Icon(Icons.search, color: kSecondaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Real-time Database Patients Queue
            Expanded(
              child: asyncPatients.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text("Không tải được bệnh nhân: $err", style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                data: (patients) {
                  if (patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 70, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            "Không tìm thấy bệnh nhân",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text("Không có dữ liệu bệnh nhân nào khớp với từ khóa tìm kiếm.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final p = patients[index];

                      final name = p['fullName']?.toString() ?? 'Chưa cập nhật tên';
                      final email = p['email']?.toString() ?? 'Không có email';
                      final phone = p['phoneNumber']?.toString() ?? 'Chưa có SĐT';
                      final cccd = p['cccd']?.toString() ?? 'Chưa có CCCD';
                      
                      final rawBhyt = p['healthInsurance']?.toString() ?? '';
                      final bhyt = rawBhyt.isNotEmpty ? rawBhyt : 'Chưa có thẻ BHYT';
                      
                      final rawAddress = p['address']?.toString() ?? '';
                      final address = rawAddress.isNotEmpty ? rawAddress : 'Chưa cập nhật địa chỉ';
                      
                      final rawGender = p['gender']?.toString() ?? '';
                      final gender = rawGender.isNotEmpty ? rawGender : 'N/A';

                      String dob = 'N/A';
                      if (p['dateOfBirth'] != null && p['dateOfBirth'].toString().isNotEmpty) {
                        try {
                          final parsedDate = DateTime.parse(p['dateOfBirth'].toString());
                          dob = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
                        } catch (_) {
                          dob = p['dateOfBirth'].toString();
                        }
                      }
                      
                      final avatar = p['avatar']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              backgroundColor: kSecondaryColor.withOpacity(0.1),
                              radius: 26,
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person, color: kSecondaryColor, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildInfoItem(Icons.phone, "SĐT: $phone"),
                                  _buildInfoItem(Icons.email, "Email: $email"),
                                  _buildInfoItem(Icons.credit_card, "CCCD: $cccd"),
                                  _buildInfoItem(Icons.assignment, "Mã BHYT: $bhyt"),
                                  _buildInfoItem(Icons.location_on, "Địa chỉ: $address"),
                                  _buildInfoItem(Icons.wc, "Giới tính: $gender  •  Ngày sinh: $dob"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}