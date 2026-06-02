import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../models/appointment.dart';
import '../../widgets/appointment_form_dialog.dart';
import 'package:intl/intl.dart';
import '../../services/api_appointment.dart';
class AppointmentScreen extends StatefulWidget {
  final List<Appointment> appointments;
  const AppointmentScreen({super.key, required this.appointments});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
 DateTime selectedDate = DateTime.now();
 List<Appointment> appointments = [];
bool loading = false;

@override
void initState() {
  super.initState();
  loadAppointmentsByDate();
}
Future<void> loadAppointmentsByDate() async {
  setState(() => loading = true);
  final date = DateFormat('yyyy-MM-dd').format(selectedDate);
  final result = await AppointmentApi.getAppointmentsByDate(date);
  setState(() {
    appointments = result.map((e) => Appointment.fromJson(e)).toList();
    loading = false;
  });

}
 Future<void> pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (picked != null) {
    setState(() {
      selectedDate = picked;
    });
     loadAppointmentsByDate();
  }
}
   Color getStatusColor(String status) {
    switch (status) {
      case "available":
        return Colors.green;
      case "booked":
        return Colors.blue;
      case "upcoming":
        return Colors.orange;
      case "full":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  String getStatusText(String status) {
    switch (status) {
      case "available":
        return "Trống";
      case "booked":
        return "Đã đặt";
      case "upcoming":
        return "Sắp tới";
      case "full":
        return "Đã kín";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
  final appointments = this.appointments;
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Quản lý lịch hẹn"),
      ),
      drawer: const ReceptionistDrawer(
        selectedMenu: "Quản lý lịch hẹn",
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// HEADER
            Row(
              children: [
                const Text(
                  "Quản lý lịch hẹn",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                ),
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nguyễn Thị Lan"),
                    Text("Lễ tân"),
                  ],
                )
              ],
            ),

            const SizedBox(height: 25),

            /// FILTER
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm bệnh nhân...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Chuyên khoa",
                      border: OutlineInputBorder(),
                    ),
                    items: const [],
                    onChanged: (v) {},
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Bác sĩ",
                      border: OutlineInputBorder(),
                    ),
                    items: const [],
                    onChanged: (v) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// STATS
            Row(
              children: [
                statCard("Trống", "7", Colors.green),
                statCard("Đã đặt", "5", Colors.blue),
                statCard("Sắp tới", "2", Colors.orange),
                statCard("Đã kín", "2", Colors.red),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Row(
                children: [
                  /// TIMELINE
                  Expanded(
                    flex: 2,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Lịch khám - ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    Row(
      children: [
        TextButton.icon(
          onPressed: pickDate,
          icon: const Icon(Icons.calendar_today),
          label: const Text("Chọn ngày"),
        ),

        const SizedBox(width: 10),

        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AppointmentFormDialog(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("Đặt lịch"),
        ),
      ],
    ),
  ],
),
                            
                            const SizedBox(height: 20),

                         Expanded(
 child:  ListView.builder(
  itemCount: appointments.length,
  itemBuilder: (_, index) {
    final item = appointments[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.patientName),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📞 ${item.phone}"),
            Text("🚻 ${item.gender}"),
            Text("🏠 ${item.address}"),
            Text("🩺 ${item.reason}"),
            Text("👨‍⚕️ ${item.doctorName}"),
            Text("🏥 ${item.departmentName}"),
          ],
        ),

        trailing: Text(
          item.time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  },
)
                         )
                        ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

            

                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget statCard(
    String title,
    String count,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}