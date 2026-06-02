import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../widgets/appointment_card.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<Appointment> list = [];
  List<Appointment> filteredList = [];

  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();

    // 🔥 AUTO REFRESH 5 GIÂY
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      await fetchData();
      return true;
    });
  }

  // ================= FETCH DATA =================
  Future<void> fetchData() async {
    try {
      setState(() => loading = true);

      final data = await AppointmentApi.getByDoctor();

      if (!mounted) return;

      setState(() {
        list = data;
        filteredList = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");

      if (!mounted) return;

      setState(() => loading = false);
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatusUI(String id, String status) async {
    try {
      await AppointmentApi.updateStatus(
        id: id,
        status: status,
      );

      setState(() {
        list = list.map((e) {
          if (e.id == id) {
            return e.copyWith(status: status);
          }
          return e;
        }).toList();

        filteredList = filteredList.map((e) {
          if (e.id == id) {
            return e.copyWith(status: status);
          }
          return e;
        }).toList();
      });
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
    }
  }

  // ================= SEARCH =================
  void searchAppointments(String query) {
    final q = query.toLowerCase();

    final result = list.where((item) {
      return item.patientName.toLowerCase().contains(q) ||
          item.phone.toLowerCase().contains(q) ||
          item.reason.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();

    setState(() {
      filteredList = result;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ================= APPBAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Lịch khám của bác sĩ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              onChanged: searchAppointments,
              decoration: InputDecoration(
                hintText: "Tìm bệnh nhân, lý do khám...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(filteredList),
          ),
        ],
      ),
    );
  }

  // ================= LIST UI =================
  Widget _buildList(List<Appointment> data) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Không có lịch khám",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = data[index];

          return AppointmentCard(
            appointment: item,
            role: "doctor",
            onUpdated: fetchData,
          );
        },
      ),
    );
  }
}
