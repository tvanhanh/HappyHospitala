import 'package:flutter/material.dart';
import '../../services/api_doctors.dart';
import 'package:go_router/go_router.dart';

const Color kPrimary = Color(0xFF1565C0);

class PatientDoctorListScreen extends StatefulWidget {
  const PatientDoctorListScreen({super.key});

  @override
  State<PatientDoctorListScreen> createState() =>
      _PatientDoctorListScreenState();
}

class _PatientDoctorListScreenState extends State<PatientDoctorListScreen> {
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filtered = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      // ================= APPBAR =================
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Tất cả Bác sĩ"),
        backgroundColor: kPrimary,
      ),

      body: Column(
        children: [
          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: search,
              decoration: InputDecoration(
                hintText: "Tìm bác sĩ, chuyên khoa...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text("Không tìm thấy bác sĩ"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final profile = doc['profile'] ?? {};

                          final name = doc['name'] ?? '';
                          final avatar = profile['avatar'] ?? '';
                          final specialty = profile['specialty'] ?? '';
                          final experience =
                              profile['experience']?.toString() ?? '0';
                          final price = profile['price']?.toString() ?? '0';

                          return GestureDetector(
                            onTap: () {
                              context.push('/doctor-detail/${doc['_id']}');
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  // ================= AVATAR =================
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                    child: avatar.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // ================= INFO =================
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          specialty,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.work,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$experience năm kinh nghiệm",
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ================= PRICE =================
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "$price đ",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchDoctors() async {
    try {
      // gọi API của bạn
      final data = await DoctorService.getDoctors();
      print("RAW DOCTORS: $data");

      setState(() {
        doctors = data;
        filtered = data;
        loading = false;
      });
    } catch (e) {
      print("ERROR FETCH: $e");
      setState(() => loading = false);
    }
  }

  void search(String key) {
    setState(() {
      filtered = doctors.where((d) {
        final name = (d['name'] ?? '').toLowerCase();
        final spec = (d['profile']?['specialty'] ?? '').toLowerCase();

        return name.contains(key.toLowerCase()) ||
            spec.contains(key.toLowerCase());
      }).toList();
    });
  }
}
