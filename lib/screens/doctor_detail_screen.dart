import 'package:flutter/material.dart';
import '../models/doctor.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailScreen extends StatelessWidget {
  final Doctor doctor;

  DoctorDetailScreen({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctor.name)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Giữ nội dung vừa đủ
              mainAxisAlignment:
                  MainAxisAlignment.center, // Căn giữa theo chiều dọc
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Căn giữa theo chiều ngang
              children: [
                // Ảnh bác sĩ
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(doctor.imageUrl,
                      width: 150, height: 150, fit: BoxFit.cover),
                ),
                SizedBox(height: 10),

                // Tên, chuyên khoa, bệnh viện
                Text(doctor.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                Text(doctor.specialty,
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                    textAlign: TextAlign.center),
                Text('🏥 ${doctor.hospital}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                SizedBox(height: 10),

                // Mô tả bác sĩ
                Text(doctor.description,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                SizedBox(height: 20),

                // Thông tin chi tiết
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.work, '${doctor.experience} năm kinh nghiệm'),
                      _buildInfoRow(Icons.location_on, doctor.address),
                      _buildInfoRow(Icons.schedule, doctor.workingHours),
                      _buildInfoRow(Icons.phone, doctor.phone),
                      _buildInfoRow(Icons.email, doctor.email),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // ✅ Nút đặt lịch khám
                ElevatedButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(doctor.bookingLink);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Không thể mở link đặt lịch")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 80),
                  ),
                  child: Text("Đặt lịch khám ngay",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Hàm tạo dòng thông tin bác sĩ
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center, // Căn giữa theo chiều ngang
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 22),
          SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
