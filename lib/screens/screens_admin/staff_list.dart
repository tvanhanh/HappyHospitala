import 'package:flutter/material.dart';

// --- PALETTE MÀU HIỆN ĐẠI ---
const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kDoctorColor = Color(0xFF00ACC1); // Màu Cyan cho Bác sĩ
const Color kNurseColor = Color(0xFFEC407A); // Màu Hồng cho Y tá/Lễ tân
const Color kStaffColor = Color(0xFFFF9800); // Màu Cam cho NV khác

class StaffManagement extends StatefulWidget {
  @override
  _StaffManagementState createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  // Dữ liệu mẫu nâng cao
  List<Map<String, dynamic>> staffList = [
    {
      'id': 'NV001',
      'name': 'Dr. Nguyễn Văn A',
      'role': 'Bác sĩ CK1',
      'department': 'Khoa Tim Mạch',
      'email': 'dr.nguyen@smartclinic.com',
      'phone': '0909123456',
      'status': 'Online', // Đang trực
      'avatarColor': kDoctorColor,
    },
    {
      'id': 'NV002',
      'name': 'Trần Thị B',
      'role': 'Y tá trưởng',
      'department': 'Phòng Cấp Cứu',
      'email': 'nurse.b@smartclinic.com',
      'phone': '0909987654',
      'status': 'Busy', // Đang bận
      'avatarColor': kNurseColor,
    },
    {
      'id': 'NV003',
      'name': 'Lê Văn C',
      'role': 'Lễ tân',
      'department': 'Sảnh Chính',
      'email': 'recep.c@smartclinic.com',
      'phone': '0912345678',
      'status': 'Offline', // Hết ca
      'avatarColor': kStaffColor,
    },
  ];

  // Danh sách gốc để lọc
  List<Map<String, dynamic>> _filteredList = [];

  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    // Gán dữ liệu ban đầu
    _filteredList = List.from(staffList);
  }

  // Hàm lọc danh sách
  void _filterList(String role) {
    setState(() {
      _selectedFilter = role;
      if (role == 'Tất cả') {
        _filteredList = staffList;
      } else {
        _filteredList = staffList
            .where((s) =>
                s['role'].contains(role) ||
                (role == 'Bác sĩ' && s['role'].contains('Bác sĩ')))
            .toList();
      }
    });
  }

  // BottomSheet Thêm/Sửa (Giả lập UI đẹp)
  void _showAddEditSheet({Map<String, dynamic>? staff}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff == null ? "Thêm Nhân Viên Mới" : "Cập Nhật Hồ Sơ",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor)),
            SizedBox(height: 20),
            TextField(
                decoration: InputDecoration(
                    labelText: "Họ và tên",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            SizedBox(height: 15),
            TextField(
                decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            SizedBox(height: 15),
            TextField(
                decoration: InputDecoration(
                    labelText: "Chức vụ",
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text("Lưu Thông Tin",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _deleteStaff(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa nhân viên này khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                staffList.removeAt(index);
                _filterList(_selectedFilter); // Refresh list
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Xóa"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,

      // --- APP BAR ---
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản Lý Nhân Sự',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('${staffList.length} nhân viên hoạt động',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
        ],
      ),

      // --- BODY ---
      body: Column(
        children: [
          // 1. BỘ LỌC (Filter Chips)
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 10),
            color: kCardColor,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Tất cả'),
                SizedBox(width: 10),
                _buildFilterChip('Bác sĩ'),
                SizedBox(width: 10),
                _buildFilterChip('Y tá'),
                SizedBox(width: 10),
                _buildFilterChip('Lễ tân'),
              ],
            ),
          ),

          // 2. DANH SÁCH NHÂN VIÊN
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                return _buildStaffCard(_filteredList[index], index);
              },
            ),
          ),
        ],
      ),

      // --- FAB ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add),
        label: Text("Thêm Nhân Sự"),
      ),
    );
  }

  // --- WIDGET CON: FILTER CHIP ---
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label ||
        (label == 'Y tá' && _selectedFilter.contains('Y tá'));
    // Logic đơn giản để demo
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        _filterList(label);
      },
      selectedColor: kPrimaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryColor : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
    );
  }

  // --- WIDGET CON: STAFF CARD (ĐẸP & HIỆN ĐẠI) ---
  Widget _buildStaffCard(Map<String, dynamic> staff, int index) {
    Color statusColor;
    switch (staff['status']) {
      case 'Online':
        statusColor = Colors.green;
        break;
      case 'Busy':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 1. AVATAR + STATUS DOT
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: staff['avatarColor'], width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: staff['avatarColor'].withOpacity(0.1),
                    child: Text(
                      staff['name'][0], // Chữ cái đầu
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: staff['avatarColor']),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(width: 16),

            // 2. THÔNG TIN CHÍNH
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff['name'],
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: staff['avatarColor'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(staff['role'],
                            style: TextStyle(
                                fontSize: 10,
                                color: staff['avatarColor'],
                                fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 8),
                      Text("• ${staff['department']}",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(staff['email'],
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),

            // 3. ACTION BUTTONS (GỌN)
            Column(
              children: [
                InkWell(
                  onTap: () => _showAddEditSheet(staff: staff),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.edit_note_rounded,
                        color: Colors.blue, size: 22),
                  ),
                ),
                InkWell(
                  onTap: () => _deleteStaff(index),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade300, size: 22),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
