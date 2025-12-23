import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/patient.dart';
import 'medical_record_page.dart';

// --- PALETTE MÀU ---
const Color kPrimaryColor = Color(0xFF009688); // blue
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF263238);
const Color kTextSecondary = Color(0xFF757575);

class PatientManagementPage extends StatefulWidget {
  @override
  _PatientManagementPageState createState() => _PatientManagementPageState();
}

class _PatientManagementPageState extends State<PatientManagementPage> {
  // Dữ liệu mẫu (Giữ nguyên)
  final List<Patient> _patients = [
    Patient(
      name: "Lưu Thị Chiến",
      age: 35,
      phone: "10656301",
      gender: "Nữ",
      department: "Sản Phụ",
      severity: 2,
      medicalId: "BN-56301",
      createdDate: DateTime(2024, 9, 9),
      updatedDate: DateTime(2024, 9, 10),
      status: "Hồ sơ chờ",
    ),
    Patient(
      name: "Nguyễn Văn A",
      age: 25,
      phone: "0987654321",
      gender: "Nam",
      department: "Nội khoa",
      severity: 1,
      medicalId: "BN-65432",
      createdDate: DateTime(2024, 8, 15),
      updatedDate: DateTime(2024, 8, 20),
      status: "Hoàn thành",
    ),
  ];

  String _searchQuery = '';
  String _sortBy = 'Tên';
  String _filterStatus = 'Tất cả';

  List<Patient> get _filteredPatients {
    List<Patient> filtered = _patients.where((patient) {
      final matchesName =
          patient.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == 'Tất cả' || patient.status == _filterStatus;
      return matchesName && matchesStatus;
    }).toList();

    if (_sortBy == 'Tên') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Ngày cập nhật') {
      filtered.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Quản Lý Bệnh Nhân',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM & LỌC (HEADER)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên bệnh nhân...',
                    prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                SizedBox(height: 12),
                // Filter & Sort Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDropdown('Lọc: $_filterStatus',
                        ['Tất cả', 'Hồ sơ chờ', 'Hoàn thành'], (val) {
                      setState(() => _filterStatus = val!);
                    }),
                    _buildDropdown(
                        'Sắp xếp: $_sortBy', ['Tên', 'Ngày cập nhật'], (val) {
                      setState(() => _sortBy = val!);
                    }),
                  ],
                ),
              ],
            ),
          ),

          // 2. DANH SÁCH BỆNH NHÂN
          Expanded(
            child: _filteredPatients.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredPatients.length,
                    separatorBuilder: (ctx, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildPatientCard(_filteredPatients[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: CARD BỆNH NHÂN ---
  Widget _buildPatientCard(Patient p) {
    Color statusColor = p.status == 'Hoàn thành' ? Colors.green : Colors.orange;
    Color avatarColor = p.gender == 'Nam' ? Colors.blue : Colors.pinkAccent;

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Lưu ý: Không truyền 'context' vào làm tham số đầu tiên của hàm .push()
            context.go('/medical-record', extra: p);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: avatarColor.withOpacity(0.1),
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: avatarColor),
                      ),
                    ),
                    SizedBox(width: 15),

                    // Thông tin chính
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text("ID: ${p.medicalId}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue)),
                              ),
                              SizedBox(width: 8),
                              Text("•  ${p.department}",
                                  style: TextStyle(
                                      fontSize: 13, color: kTextSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu 3 chấm
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (String value) {
                        if (value == 'view_record') {
                          context.go('/medical-record', extra: p);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'view_record',
                          child: Row(
                            children: [
                              Icon(Icons.assignment_ind_outlined,
                                  color: kPrimaryColor),
                              SizedBox(width: 10),
                              Text('Xem bệnh án'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.orange),
                              SizedBox(width: 10),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 24, color: Colors.grey.shade200),

                // Footer Card: Ngày & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: kTextSecondary),
                        SizedBox(width: 5),
                        Text(
                          'Cập nhật: ${p.updatedDate.day}/${p.updatedDate.month}/${p.updatedDate.year}',
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET CON: DROPDOWN ĐẸP ---
  Widget _buildDropdown(
      String hint, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 13,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600)),
          icon: Icon(Icons.arrow_drop_down, color: kPrimaryColor),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 80, color: Colors.grey.shade300),
          SizedBox(height: 10),
          Text("Không tìm thấy bệnh nhân nào",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}
