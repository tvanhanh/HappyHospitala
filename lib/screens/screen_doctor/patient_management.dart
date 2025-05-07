import 'package:flutter/material.dart';
import '../../models/patient.dart';
import 'medical_record_page.dart';
class PatientManagementPage extends StatefulWidget {
  @override
  _PatientManagementPageState createState() => _PatientManagementPageState();
}

class _PatientManagementPageState extends State<PatientManagementPage> {
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
  String _sortBy = 'Tên'; // Mặc định sắp xếp theo tên
  String _filterStatus = 'Tất cả'; // Mặc định lọc tất cả

  List<Patient> get _filteredPatients {
    List<Patient> filtered = _patients.where((patient) {
      final matchesName = patient.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == 'Tất cả' || patient.status == _filterStatus;
      return matchesName && matchesStatus;
    }).toList();

    // Sắp xếp
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
      appBar: AppBar(title: Text('Quản Lý Bệnh Nhân')),
      body: Column(
        children: [
          // Tìm kiếm, lọc và sắp xếp
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Tìm kiếm
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bệnh nhân...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                // Lọc và sắp xếp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lọc theo trạng thái
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: ['Tất cả', 'Hồ sơ chờ', 'Hoàn thành']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _filterStatus = val!;
                        });
                      },
                    ),
                    // Sắp xếp
                    DropdownButton<String>(
                      value: _sortBy,
                      items: ['Tên', 'Ngày cập nhật']
                          .map((sort) => DropdownMenuItem(
                        value: sort,
                        child: Text('Sắp xếp: $sort'),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _sortBy = val!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Danh sách bệnh nhân
          Expanded(
            child: _filteredPatients.isEmpty
                ? Center(child: Text("Không tìm thấy bệnh nhân nào"))
                : ListView.builder(
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final p = _filteredPatients[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    p.name[0],
                                    style: TextStyle(color: Colors.white, fontSize: 20),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p.name}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Bệnh án ${p.department}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.teal),
                              onSelected: (String value) {
                                if (value == 'Quản lý bệnh án') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MedicalRecordPage(patient: p)),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'Quản lý bệnh án',
                                    child: Text('Xem quản lý bệnh án'),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mã BN: ${p.medicalId}'),
                            Text('Ngày tạo: ${p.createdDate.day}/${p.createdDate.month}/${p.createdDate.year}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ngày cập nhật: ${p.updatedDate.day}/${p.updatedDate.month}/${p.createdDate.year}'),
                            Text('Hồ sơ: ${p.status}'),
                          ],
                        ),
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
}