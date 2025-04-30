import 'package:flutter/material.dart';
import '../../services/api_doctors.dart';
import 'AddDoctorScreen.dart';

class DoctorListScreen extends StatefulWidget {
  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final data = await DoctorService.getDoctors();
      setState(() {
        print(data);
        doctors = data;
      });
    } catch (e) {
      print('Lỗi khi lấy bác sĩ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách bác sĩ"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Thêm bác sĩ',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddDoctorScreen()),
              );
              if (result == true) fetchDoctors();
            },
          )
        ],
      ),
      body: doctors.isEmpty
          ? Center(child: Text('Chưa có bác sĩ nào'))
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.person, size: 40),
                    title: Text(doctor['doctorName'] ?? 'Không rõ tên'),
                    subtitle: Text(
                        'Email: ${doctor['email'] ?? 'Chưa có'}\nPhòng ban: ${doctor['departmentName'] ?? 'Không rõ'}'),
                  ),
                );
              },
            ),
    );
  }
}
