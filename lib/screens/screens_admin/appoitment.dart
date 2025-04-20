import 'package:flutter/material.dart';

class AppointmentListScreen extends StatefulWidget {
  @override
  _AppointmentListScreenState createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  List<Map<String, dynamic>> appointments = [
    {
      'id': 'APT001',
      'patientName': 'Nguyễn Văn A',
      'doctorName': 'Dr. Trần Thị B',
      'date': '2025-04-22',
      'time': '09:00 AM',
      'status': 'Đang chờ'
    },
    {
      'id': 'APT002',
      'patientName': 'Lê Thị C',
      'doctorName': 'Dr. Nguyễn Văn D',
      'date': '2025-04-22',
      'time': '10:30 AM',
      'status': 'Đã xác nhận'
    },
  ];

  void confirmAppointment(int index) {
    setState(() {
      appointments[index]['status'] = 'Đã xác nhận';
    });
  }

  void cancelAppointment(int index) {
    setState(() {
      appointments[index]['status'] = 'Đã huỷ';
    });
  }

  void viewDetails(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Chi tiết lịch hẹn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mã lịch: ${appointments[index]['id']}"),
            Text("Bệnh nhân: ${appointments[index]['patientName']}"),
            Text("Bác sĩ: ${appointments[index]['doctorName']}"),
            Text("Ngày: ${appointments[index]['date']}"),
            Text("Giờ: ${appointments[index]['time']}"),
            Text("Trạng thái: ${appointments[index]['status']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Đóng"))
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Đã xác nhận':
        return Colors.green;
      case 'Đã huỷ':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách lịch hẹn"),
      ),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: _statusColor(appointment['status'])),
              title: Text('${appointment['patientName']} → ${appointment['doctorName']}'),
              subtitle: Text('${appointment['date']} | ${appointment['time']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'confirm') confirmAppointment(index);
                  if (value == 'cancel') cancelAppointment(index);
                  if (value == 'view') viewDetails(index);
                },
                itemBuilder: (_) => [
                  if (appointment['status'] == 'Đang chờ')
                    PopupMenuItem(value: 'confirm', child: Text('Xác nhận')),
                  if (appointment['status'] != 'Đã huỷ')
                    PopupMenuItem(value: 'cancel', child: Text('Huỷ')),
                  PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
