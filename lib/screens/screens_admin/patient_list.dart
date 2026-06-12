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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: asyncPatients.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy bệnh nhân nào.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final user = patient['userId'] ?? {};
                    final profile = user['profile'] ?? {};
                    final avatar = profile['avatar']?.toString() ?? '';
                    final name = user['name']?.toString() ?? 'Chưa cập nhật';
                    final phone = profile['phone']?.toString() ?? 'Chưa cập nhật';
                    final identityCard = patient['identityCard']?.toString() ?? 'Chưa cập nhật';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(patient: patient),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: _kPrimary.withOpacity(0.1),
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty ? const Icon(Icons.person, color: _kPrimary) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(phone, style: const TextStyle(color: Colors.black87)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.badge, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('CCCD: $identityCard', style: const TextStyle(color: Colors.black87)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
