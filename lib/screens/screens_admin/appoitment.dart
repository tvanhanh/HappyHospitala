import 'package:flutter/material.dart';

// --- PALETTE MÀU (Đồng bộ) ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kPendingColor = Color(0xFFFF9800); // Cam
const Color kConfirmedColor = Color(0xFF4CAF50); // Xanh lá
const Color kCancelledColor = Color(0xFFE53935); // Đỏ
const Color kAiAccentColor = Color(0xFF673AB7); // Tím cho AI

class AppointmentListScreen extends StatefulWidget {
  @override
  _AppointmentListScreenState createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dữ liệu mẫu nâng cao (Thêm trường AI Prediction)
  List<Map<String, dynamic>> appointments = [
    {
      'id': 'APT-001',
      'patientName': 'Nguyễn Văn A',
      'doctorName': 'Dr. Trần Thị B',
      'specialty': 'Tim mạch',
      'date': '22/04/2025',
      'time': '09:00',
      'duration': '30p',
      'status': 'Đang chờ',
      'ai_note': 'Độ ưu tiên cao (Nguy cơ tăng huyết áp)'
    },
    {
      'id': 'APT-002',
      'patientName': 'Lê Thị C',
      'doctorName': 'Dr. Nguyễn Văn D',
      'specialty': 'Nội tiết',
      'date': '22/04/2025',
      'time': '10:30',
      'duration': '15p',
      'status': 'Đã xác nhận',
      'ai_note': 'Lịch trình tối ưu, không trùng lặp'
    },
    {
      'id': 'APT-003',
      'patientName': 'Phạm Văn E',
      'doctorName': 'Dr. Lê F',
      'specialty': 'Xương khớp',
      'date': '23/04/2025',
      'time': '14:00',
      'duration': '45p',
      'status': 'Đã huỷ',
      'ai_note': 'Bệnh nhân thường xuyên hủy hẹn'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Logic lọc danh sách theo Tab
  List<Map<String, dynamic>> getFilteredAppointments(int tabIndex) {
    if (tabIndex == 0) return appointments; // Tất cả
    if (tabIndex == 1)
      return appointments.where((a) => a['status'] == 'Đang chờ').toList();
    if (tabIndex == 2)
      return appointments.where((a) => a['status'] == 'Đã xác nhận').toList();
    return [];
  }

  // Các hàm xử lý giữ nguyên logic
  void confirmAppointment(String id) {
    setState(() {
      final index = appointments.indexWhere((element) => element['id'] == id);
      if (index != -1) appointments[index]['status'] = 'Đã xác nhận';
    });
  }

  void cancelAppointment(String id) {
    setState(() {
      final index = appointments.indexWhere((element) => element['id'] == id);
      if (index != -1) appointments[index]['status'] = 'Đã huỷ';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Quản Lý Lịch Hẹn",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor, // Màu nền xanh
        elevation: 0,
        centerTitle: true,
        iconTheme:
            IconThemeData(color: Colors.white), // Màu nút back/menu là trắng
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white, // Màu gạch chân -> Trắng
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ duyệt"),
            Tab(text: "Sắp tới"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(getFilteredAppointments(0)),
          _buildList(getFilteredAppointments(1)),
          _buildList(getFilteredAppointments(2)),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
            Text("Không có lịch hẹn nào", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return _buildModernAppointmentCard(data[index]);
      },
    );
  }

  // --- CARD LỊCH HẸN HIỆN ĐẠI ---
  Widget _buildModernAppointmentCard(Map<String, dynamic> apt) {
    Color statusColor;
    switch (apt['status']) {
      case 'Đã xác nhận':
        statusColor = kConfirmedColor;
        break;
      case 'Đã huỷ':
        statusColor = kCancelledColor;
        break;
      default:
        statusColor = kPendingColor;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.blueGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Phần trên: Thông tin chính
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột Giờ (Bên trái)
                Column(
                  children: [
                    Text(apt['time'],
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800)),
                    Text(apt['date'].substring(0, 5),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey)), // Lấy ngày/tháng
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(apt['duration'],
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                SizedBox(width: 16),

                // Vạch kẻ dọc
                Container(height: 60, width: 1, color: Colors.grey.shade200),
                SizedBox(width: 16),

                // Cột Thông tin (Ở giữa)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(apt['patientName'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text("${apt['doctorName']}",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                      Text("Khoa: ${apt['specialty']}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),

                // Badge Trạng thái & Menu (Bên phải)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        apt['status'],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildActionMenu(apt), // Menu 3 chấm
                  ],
                )
              ],
            ),
          ),

          // Phần dưới: AI Suggestion (Điểm nhấn đề tài)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: kAiAccentColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16)),
                border: Border(
                    top: BorderSide(color: kAiAccentColor.withOpacity(0.1)))),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: kAiAccentColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "AI Note: ${apt['ai_note']}",
                    style: TextStyle(
                        fontSize: 12,
                        color: kAiAccentColor.withOpacity(0.8),
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- POPUP MENU (Nút 3 chấm) ---
  Widget _buildActionMenu(Map<String, dynamic> apt) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'confirm') confirmAppointment(apt['id']);
        if (value == 'cancel') cancelAppointment(apt['id']);
        if (value == 'detail') _showDetailDialog(apt);
      },
      itemBuilder: (context) => [
        if (apt['status'] == 'Đang chờ')
          PopupMenuItem(
            value: 'confirm',
            child: Row(children: [
              Icon(Icons.check, color: kConfirmedColor),
              SizedBox(width: 10),
              Text("Xác nhận")
            ]),
          ),
        if (apt['status'] != 'Đã huỷ')
          PopupMenuItem(
            value: 'cancel',
            child: Row(children: [
              Icon(Icons.cancel, color: kCancelledColor),
              SizedBox(width: 10),
              Text("Huỷ hẹn")
            ]),
          ),
        PopupMenuItem(
          value: 'detail',
          child: Row(children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text("Chi tiết")
          ]),
        ),
      ],
    );
  }

  // --- DIALOG CHI TIẾT ---
  void _showDetailDialog(Map<String, dynamic> apt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.calendar_today, color: kPrimaryColor),
          SizedBox(width: 10),
          Text("Chi tiết lịch hẹn")
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Mã phiếu:", apt['id']),
            _buildDetailRow("Bệnh nhân:", apt['patientName']),
            _buildDetailRow("Bác sĩ:", apt['doctorName']),
            _buildDetailRow("Thời gian:", "${apt['time']} - ${apt['date']}"),
            Divider(),
            Text("Đánh giá từ AI:",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kAiAccentColor)),
            Text(apt['ai_note'], style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}
