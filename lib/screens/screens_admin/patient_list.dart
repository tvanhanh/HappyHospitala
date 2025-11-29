import 'package:flutter/material.dart';
import './patient_detail.dart';

// --- PALETTE MÀU SẮC HIỆN ĐẠI ---
const Color kPrimaryColor = Color(0xFF1565C0); // Xanh dương đậm
const Color kAccentColor = Color(0xFF4CAF50); // Xanh lá (cho Nữ)
const Color kMaleColor = Color(0xFF2196F3); // Xanh dương (cho Nam)
const Color kBackgroundColor = Color(0xFFF5F7FA); // Nền xám nhạt

class PatientListScreen extends StatelessWidget {
  // DỮ LIỆU MẪU (Giữ nguyên cấu trúc của bạn, không đụng tới backend)
  final List<Map<String, String>> patients = [
    {
      'name': 'Nguyễn Văn A',
      'dob': '12/05/1985',
      'gender': 'Nam',
      'phone': '0901234567',
      'address': '123 Lê Lợi, Q1, TP.HCM'
    },
    {
      'name': 'Trần Thị B',
      'dob': '25/11/1990',
      'gender': 'Nữ',
      'phone': '0912345678',
      'address': '456 Hai Bà Trưng, Q3, TP.HCM'
    },
    {
      'name': 'Lê Văn C',
      'dob': '05/08/1978',
      'gender': 'Nam',
      'phone': '0987654321',
      'address': '789 Điện Biên Phủ, Q.Bình Thạnh, TP.HCM'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Màu nền hiện đại
      appBar: AppBar(
        shadowColor: kPrimaryColor.withOpacity(0.5),
        centerTitle: true,
      ),

      // Nút thêm bệnh nhân (UI only - chưa có logic backend)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Điều hướng đến màn hình thêm bệnh nhân
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Chức năng thêm bệnh nhân sẽ sớm ra mắt!")));
        },
        label: Text("Thêm Bệnh Nhân"),
        icon: Icon(Icons.person_add_alt_1_rounded),
        backgroundColor: kPrimaryColor,
      ),

      body: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return _buildPatientCard(context, patient);
          },
        ),
      ),
    );
  }

  // --- HÀM XÂY DỰNG CARD BỆNH NHÂN (Widget con) ---
  Widget _buildPatientCard(BuildContext context, Map<String, String> patient) {
    final isMale = patient['gender'] == 'Nam';
    final genderColor = isMale ? kMaleColor : kAccentColor;
    final genderIcon = isMale ? Icons.male_rounded : Icons.female_rounded;

    return Card(
      elevation: 4, // Đổ bóng mềm
      shadowColor: Colors.black12,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)), // Bo góc tròn trịa
      child: InkWell(
        // Thêm hiệu ứng gợn sóng khi nhấn
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patient: patient),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. AVATAR HIỆN ĐẠI VỚI GIỚI TÍNH
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: genderColor.withOpacity(0.1),
                    child: Icon(Icons.person_rounded,
                        color: genderColor, size: 32),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(genderIcon, color: genderColor, size: 18),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16),

              // 2. THÔNG TIN CHÍNH
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'] ?? 'Tên không xác định',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),

                    // Hàng thông tin phụ 1: Ngày sinh
                    Row(
                      children: [
                        Icon(Icons.cake_rounded,
                            size: 16, color: Colors.grey.shade500),
                        SizedBox(width: 6),
                        Text(
                          patient['dob'] ?? '--/--/----',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),

                    // Hàng thông tin phụ 2: Số điện thoại
                    Row(
                      children: [
                        Icon(Icons.phone_enabled_rounded,
                            size: 16, color: Colors.grey.shade500),
                        SizedBox(width: 6),
                        Text(
                          patient['phone'] ?? 'Không có SĐT',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. ICON ĐIỀU HƯỚNG
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: kPrimaryColor.withOpacity(0.7)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
