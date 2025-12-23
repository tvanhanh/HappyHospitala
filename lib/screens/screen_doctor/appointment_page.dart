import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_appointment.dart';
import 'update_medical.dart';
import 'chatAI_screen.dart';

// --- CẤU HÌNH MÀU SẮC CHUNG (Để đồng bộ giao diện) ---
const Color kPrimaryColor = Color(0xFF009688); // blue
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextTitle = Color(0xFF263238);
const Color kTextBody = Color(0xFF546E7A);

class AppointmentPage extends StatefulWidget {
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // ---------------------------------------------------------
  // ⚠️ PHẦN LOGIC GIỮ NGUYÊN (KHÔNG CHỈNH SỬA)
  // ---------------------------------------------------------
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
  // ---------------------------------------------------------
  // 🔥 PHẦN GIAO DIỆN DANH SÁCH (ĐÃ LÀM ĐẸP)
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch Hẹn Khám',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadAppointments,
        color: kPrimaryColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: appointments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    return _buildModernCard(appt);
                  },
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
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 10),
          Text(
            'Không có lịch hẹn',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> appt) {
    final patientName = appt['patientName']?.toString() ?? 'Chưa có tên';
    final date = appt['date']?.toString() ?? '--/--';
    final time = appt['time']?.toString() ?? '--:--';
    final status = appt['status']?.toString() ?? 'Chưa xác nhận';

    // Màu sắc theo trạng thái
    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.shade50;
    if (status == 'Đã khám' || status == 'Hoàn thành') {
      statusColor = Colors.green;
      statusBg = Colors.green.shade50;
    } else if (status == 'Khách hủy' || status == 'Đã hủy') {
      statusColor = Colors.red;
      statusBg = Colors.red.shade50;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (appt['id'] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('ID lịch hẹn không hợp lệ'),
                  backgroundColor: Colors.red),
            );
            return;
          }
          final result =
              await context.push('/doctor/appointment-detail', extra: appt);
          if (result == true) {
            loadAppointments(); // Làm mới danh sách sau khi cập nhật
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ngày giờ
                  Row(
                    children: [
                      Icon(Icons.access_time_filled,
                          size: 16, color: kPrimaryColor),
                      SizedBox(width: 6),
                      Text(
                        "$time - $date",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextTitle),
                      ),
                    ],
                  ),
                  // Badge trạng thái
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor),
                    ),
                  )
                ],
              ),
              Divider(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: kPrimaryColor),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextTitle),
                        ),
                        SizedBox(height: 4),
                        Text("Bệnh nhân",
                            style: TextStyle(fontSize: 12, color: kTextBody)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey.shade400)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TRANG CHI TIẾT (ĐÃ LÀM ĐẸP UI - GIỮ NGUYÊN LOGIC)
// ============================================================================

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({Key? key, required this.appointment})
      : super(key: key);

  // ---------------------------------------------------------
  // ⚠️ PHẦN LOGIC GIỮ NGUYÊN (KHÔNG CHỈNH SỬA)
  // ---------------------------------------------------------
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                _buildStatusOption(sheetContext, appointmentId, context,
                    'Đã khám', Icons.check_circle, Colors.green),
                _buildStatusOption(sheetContext, appointmentId, context,
                    'Khách hủy', Icons.cancel, Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    BuildContext sheetContext,
    String appointmentId,
    BuildContext parentContext,
    String status,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
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
  // ---------------------------------------------------------
  // 🔥 PHẦN GIAO DIỆN CHI TIẾT (ĐÃ LÀM ĐẸP)
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    print('Dữ liệu appointment: $appointment');

    final status = appointment['status']?.toString() ?? 'Chưa xác nhận';
    Color statusColor = Colors.orange;
    if (status == 'Đã khám') statusColor = Colors.green;
    if (status == 'Khách hủy') statusColor = Colors.red;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. HEADER TRẠNG THÁI
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_ind, size: 40, color: statusColor),
                  SizedBox(height: 10),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      final appointmentId = appointment['id']?.toString() ?? '';
                      _showStatusSelectionMenu(context, appointmentId);
                    },
                    icon: Icon(Icons.edit, size: 18, color: statusColor),
                    label: Text("Cập nhật trạng thái",
                        style: TextStyle(color: statusColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: statusColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 20),

            // 2. THẺ THÔNG TIN BỆNH NHÂN
            _buildSectionCard(
                title: "Thông Tin Bệnh Nhân",
                icon: Icons.person,
                children: [
                  _detailRow('Họ tên', appointment['patientName']?.toString()),
                  _detailRow('Email', appointment['email']?.toString()),
                  _detailRow('Lý do khám', appointment['reason']?.toString()),
                ]),

            SizedBox(height: 16),

            // 3. THẺ CHI TIẾT LỊCH HẸN
            _buildSectionCard(
                title: "Chi Tiết Lịch Hẹn",
                icon: Icons.calendar_month,
                children: [
                  _detailRow('Ngày', appointment['date']?.toString()),
                  _detailRow('Giờ', appointment['time']?.toString()),
                  _detailRow('Khoa', appointment['departmentName']?.toString()),
                  _detailRow('Bác sĩ phụ trách',
                      appointment['doctorName']?.toString()),
                ]),

            SizedBox(height: 24),

            // 4. CÁC NÚT CHỨC NĂNG
            Text("Thao Tác Nhanh",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 10),

            _buildActionButton(
              icon: Icons.note_add,
              label: "Thêm thông tin bệnh án",
              color: Colors.blue,
              onTap: () {
                final appointmentId = appointment['id']?.toString() ?? '';
                print('appointmentId: $appointmentId');
                context.go('/doctor/addPatient', extra: appointment);
              },
            ),

            SizedBox(height: 12),

            _buildActionButton(
              icon: Icons.analytics,
              label: "Dự đoán bệnh (AI)",
              color: Colors.purple,
              onTap: () {
                context.go(
                  '/diagnosis',
                );
              },
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget con để hiển thị card thông tin
  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextTitle)),
            ],
          ),
          Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  // Widget con để hiển thị từng dòng chi tiết
  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: kTextBody),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Không có",
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: kTextTitle),
            ),
          ),
        ],
      ),
    );
  }

  // Widget con cho nút bấm lớn
  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Text(label,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
