import 'package:flutter/material.dart';
import '../../services/api_appointment.dart';

class AppointmentPage extends StatefulWidget {
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data = await AddAppointments.getAppoitment();
    setState(() {
      appointments = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Hẹn Khám'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: appointments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return _buildAppointmentCard(appt);
                },
              ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
        title: Text(
          appt['patientName'] ?? 'Chưa có tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day: ${appt['date']}'),
            Text('Hour: ${appt['time']}'),
            Text('status: ${appt['status']}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(appointment: appt),
            ),
          );
        },
      ),
    );
  }
}

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({Key? key, required this.appointment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết lịch hẹn'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Tên bệnh nhân', appointment['patientName']),
                _detailRow('Ngày', appointment['date']),
                _detailRow('Giờ', appointment['time']),
                _detailRow('Khoa', appointment['departmentName']),
                _detailRow('Lý do', appointment['reason']),
                _detailRow('Trạng thái', appointment['status']),
                _detailRow('Mã bác sĩ', appointment['doctorId']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '$label: ${value ?? "Không có"}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
