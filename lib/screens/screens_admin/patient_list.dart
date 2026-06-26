import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/patient_provider.dart';
import 'patient_detail.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF5F7FA);

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final asyncPatients = ref.watch(patientProvider(_searchQuery));

    return Scaffold(
      backgroundColor: _kBackground,
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 900), // Gom UI vào giữa màn hình
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: asyncPatients.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Lỗi tải dữ liệu: $err')),
                  data: (patients) {
                    if (patients.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy bệnh nhân nào.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];

                        final id = patient['_id'] ?? '';
                        final avatar = patient['avatar']?.toString() ?? '';
                        final name =
                            patient['fullName']?.toString() ?? 'Chưa cập nhật';
                        final phone = patient['phoneNumber']?.toString() ??
                            'Chưa cập nhật';
                        final cccd =
                            patient['cccd']?.toString() ?? 'Chưa cập nhật';
                        final gender = patient['gender']?.toString() ?? '';
                        final status = patient['status']?.toString() ?? '';

                        final isInactive = status == 'inactive';

                        return Card(
                          elevation:
                              0, // Đổi sang flat design giống chuyên khoa
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PatientDetailScreen(patient: patient),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _kPrimary.withOpacity(0.1),
                                    backgroundImage: avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                    child: avatar.isEmpty
                                        ? const Icon(Icons.person,
                                            color: _kPrimary)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),

                                  // Thông tin chính
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: _kPrimary),
                                            ),
                                            const SizedBox(width: 8),
                                            if (gender.isNotEmpty)
                                              Icon(
                                                gender.toLowerCase() == 'nam'
                                                    ? Icons.male
                                                    : Icons.female,
                                                size: 16,
                                                color: gender.toLowerCase() ==
                                                        'nam'
                                                    ? Colors.blue
                                                    : Colors.pink,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(phone,
                                                style: const TextStyle(
                                                    color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.badge,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('CCCD: $cccd',
                                                style: const TextStyle(
                                                    color: Colors.black87)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Nhãn trạng thái & Icon điều hướng
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isInactive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('Đã khóa',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      const Icon(Icons.arrow_forward_ios,
                                          color: Colors.grey, size: 18),
                                    ],
                                  )
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo Tên, SĐT, CCCD...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
