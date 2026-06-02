import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../widgets/appointment_card.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<Appointment> list = [];
  bool loading = true;
  List<Appointment> filteredList = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await AppointmentApi.getByPatient();

      setState(() {
        list = data;
        filteredList = data; // 👈 thêm list lọc
        loading = false;
      });
    } catch (e) {
      print("ERROR LOAD: $e");
      setState(() => loading = false);
    }
  }

  void searchAppointments(String query) {
    final result = list.where((item) {
      final doctor = item.doctorName.toString().toLowerCase();
      final reason = item.reason.toLowerCase();
      final date = item.date.toLowerCase();

      return doctor.contains(query.toLowerCase()) ||
          reason.contains(query.toLowerCase()) ||
          date.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredList = result;
    });
  }

  Future<void> refresh() async {
    setState(() => loading = true);
    await fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),

      // ================= APPBAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1389D3),

        // 👈 NÚT BACK
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),

        title: const Text("Lịch hẹn của tôi"),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              onChanged: searchAppointments,
              decoration: InputDecoration(
                hintText: "Tìm kiếm lịch hẹn...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),

      // ================= BODY =================
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              child: list.isEmpty ? _empty() : _buildList(),
            ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return AppointmentCard(
          appointment: list[index],
          role: "patient",
          onUpdated: fetchData,
        );
      },
    );
  }

  // ================= EMPTY STATE =================
  Widget _empty() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.calendar_month_outlined, size: 90, color: Colors.grey),
        SizedBox(height: 12),
        Center(
          child: Text(
            "Bạn chưa có lịch hẹn nào",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
