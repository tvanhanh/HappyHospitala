import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_doctors.dart';
import 'AddDoctorScreen.dart';
import 'dart:math'; // Để random màu avatar

// --- PALETTE MÀU HIỆN ĐẠI ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A237E);
const Color kTextSecondary = Colors.grey;

class DoctorListScreen extends StatefulWidget {
  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  bool isLoading = true; // ✅ THÊM: Trạng thái đang tải
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    setState(() => isLoading = true); // Bắt đầu tải
    try {
      final data = await DoctorService.getDoctors();

      // ✅ DEBUG: In ra để xem dữ liệu API trả về có đúng cấu trúc không
      print("Dữ liệu API Raw: $data");

      setState(() {
        // ✅ QUAN TRỌNG: Ép kiểu dữ liệu an toàn để tránh lỗi
        doctors = List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)));
        filteredDoctors = doctors;
        isLoading = false; // Tải xong
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Lỗi hiển thị bác sĩ: $e');

      // Hiện thông báo lỗi lên màn hình để dễ biết
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = doctors;
    } else {
      results = doctors
          .where((user) =>
              (user["doctorName"] ?? "") // Thêm ?? "" để tránh lỗi null
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredDoctors = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Đội Ngũ Bác Sĩ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            // Chỉ hiện số lượng khi đã tải xong
            if (!isLoading)
              Text("${doctors.length} chuyên gia hàng đầu",
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // HEADER & SEARCH BAR
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: "Tìm kiếm bác sĩ...",
                prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // DANH SÁCH BÁC SĨ
          Expanded(
            child: isLoading
                ? Center(
                    child:
                        CircularProgressIndicator()) // ✅ Hiện vòng xoay khi đang tải
                : RefreshIndicator(
                    onRefresh: fetchDoctors,
                    child: filteredDoctors.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredDoctors.length,
                            itemBuilder: (context, index) {
                              return _buildDoctorCard(filteredDoctors[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/admin/add-doctor');
          if (result == true) fetchDoctors();
        },
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add_alt_1),
        label: Text("Thêm Bác Sĩ"),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    // ✅ Kiểm tra kỹ tên trường dữ liệu (Key)
    // Nếu API trả về 'name' thay vì 'doctorName', hãy sửa ở đây
    String name = doctor['doctorName'] ?? doctor['name'] ?? 'Không rõ tên';
    String department =
        doctor['departmentName'] ?? doctor['department'] ?? 'Chưa phân khoa';
    String email = doctor['email'] ?? 'Chưa cập nhật';

    Color avatarColor = Colors.primaries[name.length % Colors.primaries.length];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: avatarColor.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(name),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          department,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: kTextSecondary),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                  fontSize: 13, color: kTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () {},
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined,
              size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text("Chưa tìm thấy bác sĩ nào",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.length > 1) {
      return "${nameParts[0][0]}${nameParts.last[0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
