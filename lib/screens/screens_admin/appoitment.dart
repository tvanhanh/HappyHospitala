import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/services/api_appointment.dart';

const Color kPrimaryColor = Color(0xFF1565C0);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kPendingColor = Color(0xFFFF9800);
const Color kConfirmedColor = Color(0xFF4CAF50);
const Color kCancelledColor = Color(0xFFE53935);
const Color kAiAccentColor = Color(0xFF673AB7);

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<List<dynamic>> futureAppointments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    futureAppointments = AppointmentApi.getAllAppointments();
  }

  void reload() {
    setState(() {
      futureAppointments = AppointmentApi.getAllAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= FILTER =================
  List<dynamic> filterData(List<dynamic> data, int tab) {
    if (tab == 0) return data;

    if (tab == 1) {
      return data.where((a) => a['status'] == 'pending').toList();
    }

    if (tab == 2) {
      return data.where((a) => a['status'] == 'confirmed').toList();
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Quản Lý Lịch Hẹn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ duyệt"),
            Tab(text: "Sắp tới"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(0),
          _buildTab(1),
          _buildTab(2),
        ],
      ),
    );
  }

  // ================= TAB =================
  Widget _buildTab(int index) {
    return FutureBuilder<List<dynamic>>(
      future: futureAppointments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Lỗi tải dữ liệu"));
        }

        final data = snapshot.data ?? [];
        final filtered = filterData(data, index);

        if (filtered.isEmpty) {
          return const Center(
            child: Text("Không có lịch hẹn"),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildModernAppointmentCard(filtered[index]);
            },
          ),
        );
      },
    );
  }

  // ================= CARD =================
  Widget _buildModernAppointmentCard(Map<String, dynamic> apt) {
    Color statusColor;

    switch (apt['status']) {
      case 'confirmed':
        statusColor = kConfirmedColor;
        break;
      case 'cancelled':
        statusColor = kCancelledColor;
        break;
      default:
        statusColor = kPendingColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  apt['time'] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (apt['date'] ?? "").toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 60, color: Colors.grey.shade200),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt['patientName'] ?? "",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    apt['doctorName'] ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    apt['specialty'] ?? "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                apt['status'] ?? "",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
