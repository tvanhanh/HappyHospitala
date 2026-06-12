import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../services/api_appointment.dart';
import '../../widgets/appointment_card.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  List<Appointment> list = [];
  List<Appointment> filteredList = [];

  bool loading = true;

  late TabController tabController;

  final tabs = ["pending", "confirmed", "completed", "cancelled"];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    fetchData();
  }

  // ================= FETCH DATA =================
  Future<void> fetchData() async {
    try {
      final data = await AppointmentApi.getAllAppointments();

      setState(() {
        list = data;
        filteredList = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD APPOINTMENTS: $e");
      setState(() => loading = false);
    }
  }

  // ================= SEARCH =================
  void searchAppointments(String query) {
    final q = query.toLowerCase();

    final result = list.where((item) {
      return item.patientName.toLowerCase().contains(q) ||
          item.reason.toLowerCase().contains(q) ||
          item.phone.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();

    setState(() {
      filteredList = result;
    });
  }

  // ================= FILTER BY STATUS =================
  List<Appointment> filterByStatus(String status) {
    return filteredList.where((e) => e.status == status).toList();
  }

  // ================= REFRESH =================
  Future<void> refresh() async {
    setState(() => loading = true);
    await fetchData();
  }

  @override
  void dispose() {
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: "Chờ duyệt"),
                    Tab(text: "Đã xác nhận"),
                    Tab(text: "Hoàn thành"),
                    Tab(text: "Đã hủy"),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchController,
                  onChanged: searchAppointments,
                  decoration: InputDecoration(
                    hintText: "Tìm bệnh nhân, SĐT, lý do...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ================= TABS CONTENT =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: tabController,
                    children: tabs.map((status) {
                      final l = filterByStatus(status);
                      return _buildTab(l);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ================= TAB UI =================
  Widget _buildTab(List<Appointment> data) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Không có lịch hẹn",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return AppointmentCard(
            appointment: data[index],
            role: "admin",
            onUpdated: fetchData,
          );
        },
      ),
    );
  }
}
