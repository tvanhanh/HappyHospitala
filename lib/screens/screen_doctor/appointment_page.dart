import 'package:flutter/material.dart';
import '../../services/api_appointment.dart';
import 'update_medical.dart';
import 'chatAI_screen.dart';

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
    try {
      final data = await AddAppointments.getAppoitment();
      print('Dữ liệu từ API: $data'); // Debug dữ liệu từ API
      setState(() {
        appointments = data != null
            ? data.where((appt) => appt['id'] != null).toList()
            : [];
      });
    } catch (e) {
      print('Lỗi khi tải lịch hẹn: $e'); // Log lỗi chi tiết
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch hẹn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        appointments = []; // Gán danh sách rỗng nếu có lỗi
      });
    }
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
            ? const Center(
                child: Text(
                  'Không có lịch hẹn',
                  style: TextStyle(fontSize: 18),
                ),
              )
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
    final patientName = appt['patientName']?.toString() ?? 'Chưa có tên';
    final date = appt['date']?.toString() ?? 'Không có';
    final time = appt['time']?.toString() ?? 'Không có';
    final status = appt['status']?.toString() ?? 'Chưa xác nhận';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day: $date'),
            Text('Hour: $time'),
            Text('Status: $status'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          if (appt['id'] == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID lịch hẹn không hợp lệ'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(appointment: appt),
            ),
          );
          if (result == true) {
            loadAppointments(); // Làm mới danh sách sau khi cập nhật
          }
        },
      ),
    );
  }
}

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({Key? key, required this.appointment})
      : super(key: key);

  Future<void> updateStatus(
      BuildContext context, String id, String newStatus) async {
    if (id == null || id.isEmpty) {
      showSnackbar(context, 'Không tìm thấy ID lịch hẹn', isError: true);
      return;
    }

    try {
      await AddAppointments.updateStatus(id, newStatus);
      if (!context.mounted) return;
      showSnackbar(context, 'Đã cập nhật trạng thái thành "$newStatus"');
      Navigator.pop(context, true); // Trả về true để làm mới danh sách
    } catch (e) {
      if (context.mounted) {
        showSnackbar(context, 'Lỗi khi cập nhật trạng thái: $e', isError: true);
      }
      print('Lỗi khi cập nhật trạng thái: $e');
    }
  }

  void showSnackbar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showStatusSelectionMenu(BuildContext context, String appointmentId) {
    if (appointmentId.isEmpty) {
      showSnackbar(context, 'ID lịch hẹn không hợp lệ', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Cập nhật trạng thái',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                _buildStatusOption(
                    sheetContext, appointmentId, context, 'Đã khám'),
                _buildStatusOption(
                    sheetContext, appointmentId, context, 'khách hủy'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext sheetContext, String appointmentId,
      BuildContext parentContext, String status) {
    return ListTile(
      leading: Icon(
        status == 'Đã xác nhận' ? Icons.check_circle : Icons.cancel,
        color: status == 'Đã xác nhận' ? Colors.green : Colors.red,
      ),
      title: Text(
        status,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(sheetContext); // Đóng bottom sheet
        _confirmChangeStatus(parentContext, appointmentId, status);
      },
    );
  }

  void _confirmChangeStatus(
      BuildContext context, String appointmentId, String newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thay đổi trạng thái'),
          content: Text('Bạn có chắc muốn đổi trạng thái thành "$newStatus"?'),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            TextButton(
              child: const Text('Xác nhận'),
              onPressed: () async {
                Navigator.pop(dialogContext); // Đóng dialog
                await updateStatus(context, appointmentId, newStatus);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Dữ liệu appointment: $appointment');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn'),
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
                _detailRow('Tên bệnh nhân',
                    appointment['patientName']?.toString() ?? 'Không có'),
                _detailRow(
                    'email', appointment['email']?.toString() ?? 'Không có'),
                _detailRow(
                    'Ngày', appointment['date']?.toString() ?? 'Không có'),
                _detailRow(
                    'Giờ', appointment['time']?.toString() ?? 'Không có'),
                _detailRow('Khoa',
                    appointment['departmentName']?.toString() ?? 'Không có'),
                _detailRow(
                    'Lý do', appointment['reason']?.toString() ?? 'Không có'),
                _detailRow('Trạng thái',
                    appointment['status']?.toString() ?? 'Chưa xác nhận'),
                _detailRow('Mã bác sĩ',
                    appointment['doctorName']?.toString() ?? 'Không có'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final appointmentId =
                            appointment['id']?.toString() ?? '';
                        print(
                            'appointmentId trước khi gọi _showStatusSelectionMenu: $appointmentId');
                        _showStatusSelectionMenu(context, appointmentId);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Cập nhật trạng thái'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final appointmentId =
                              appointment['id']?.toString() ?? '';
                          print('appointmentId: $appointmentId');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddPatientForm(appointment: appointment),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Thêm thông tin bệnh án'),
                      ),
                      const SizedBox(height: 16), // khoảng cách giữa 2 nút
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiagnosisFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text('Dự đoán'),
                      ),
                    ],
                  ),
                )
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
