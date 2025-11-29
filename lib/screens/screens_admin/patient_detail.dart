import 'package:flutter/material.dart';

// --- PALETTE MÀU (Đồng bộ với PatientListScreen) ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient; // Đổi thành dynamic để linh hoạt hơn

  const PatientDetailScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Giả lập dữ liệu nếu thiếu
    final String name = patient['name'] ?? 'Chưa cập nhật';
    final String id = patient['id'] ??
        'BN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final String gender = patient['gender'] ?? 'Khác';
    final bool isMale = gender == 'Nam';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar trong suốt để hiển thị Header đẹp hơn
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: () {
              // TODO: Chuyển sang màn sửa
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER PROFILE ---
            _buildProfileHeader(name, id, isMale),

            // --- 2. NỘI DUNG CHI TIẾT ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Thẻ chỉ số nhanh
                  _buildQuickStatsCard(patient),
                  SizedBox(height: 20),

                  // Thẻ thông tin cá nhân
                  _buildInfoCard(patient),
                  SizedBox(height: 20),

                  // Thẻ lịch sử khám (Demo)
                  _buildHistoryCard(),
                  SizedBox(height: 30),

                  // Nút Xóa (Nguy hiểm nên để riêng)
                  _buildDeleteButton(context),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON: HEADER ---
  Widget _buildProfileHeader(String name, String id, bool isMale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 100, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
              color: kPrimaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Avatar lớn có viền
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                isMale ? Icons.face_rounded : Icons.face_3_rounded,
                size: 60,
                color: isMale ? Colors.blue : Colors.pink,
              ),
            ),
          ),
          SizedBox(height: 15),
          // Tên
          Text(
            name,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          // Mã BN
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Mã hồ sơ: $id",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: CHỈ SỐ NHANH ---
  Widget _buildQuickStatsCard(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.bloodtype, "Nhóm máu", data['bloodType'] ?? "O+",
              Colors.red),
          _buildVerticalDivider(),
          _buildStatItem(Icons.monitor_weight, "Cân nặng", "65 kg",
              Colors.blue), // Demo data
          _buildVerticalDivider(),
          _buildStatItem(
              Icons.height, "Chiều cao", "170 cm", Colors.blue), // Demo data
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- WIDGET CON: THÔNG TIN CHI TIẾT ---
  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Thông tin liên hệ",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor)),
          Divider(height: 25),
          _buildInfoRow(Icons.cake_rounded, "Ngày sinh", data['dob']),
          _buildInfoRow(Icons.transgender_rounded, "Giới tính", data['gender']),
          _buildInfoRow(Icons.phone_rounded, "Điện thoại", data['phone']),
          _buildInfoRow(Icons.location_on_rounded, "Địa chỉ", data['address']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                SizedBox(height: 2),
                Text(value ?? '---',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET CON: LỊCH SỬ KHÁM (DEMO) ---
  Widget _buildHistoryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Lịch sử khám gần đây",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor)),
              Icon(Icons.history, color: Colors.grey),
            ],
          ),
          Divider(height: 25),
          _buildHistoryItem("10/10/2023", "Khám tổng quát", "Bs. Lê Minh"),
          _buildHistoryItem("15/05/2023", "Xét nghiệm máu", "Bs. Trần Hà"),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String reason, String doctor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(date,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(doctor,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET CON: NÚT XÓA ---
  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Logic xóa giữ nguyên
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Xác nhận xóa"),
              content: Text(
                  "Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa hồ sơ này?"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Hủy", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                    Navigator.pop(context); // Quay về danh sách
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Đã xóa hồ sơ bệnh nhân"),
                        backgroundColor: Colors.red));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Text("Xóa vĩnh viễn"),
                ),
              ],
            ),
          );
        },
        icon: Icon(Icons.delete_forever, color: Colors.red),
        label: Text("Xóa Hồ Sơ Bệnh Nhân",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
