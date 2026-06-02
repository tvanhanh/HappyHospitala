import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/receptionist_drawer.dart';
class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({super.key});

  static const Color kPrimaryColor = Color(0xFF0D47A1);
  static const Color kSecondaryColor = Color(0xFF1976D2);
  static const Color kBackgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Phòng khám ABC - Hệ thống quản lý",
        ),
        backgroundColor: kPrimaryColor,
      ),

        drawer: const ReceptionistDrawer(
        selectedMenu: "Thông báo",
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý bệnh nhân',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Tìm theo tên/SĐT/CCCD/Mã bệnh nhân...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm bệnh nhân'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Danh sách bệnh nhân sẽ hiển thị ở đây',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}