import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
// --- PALETTE MÀU SẮC ---
const kPrimaryColor = Color(0xFF0D47A1); // Xanh đậm
const kSecondaryColor = Color(0xFF1976D2);
const kAccentColor = Color(0xFF4CAF50); // Xanh lá
const kBackgroundColor = Color(0xFFF5F7FA);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF333333);

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Phòng khám ABC - Hệ thống quản lý"),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
    drawer: const ReceptionistDrawer(
  selectedMenu: "Tổng quan",
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildChartsSection(),
            const SizedBox(height: 20),
            _buildRecentAppointments(),
          ],
        ),
      ),
    );
  }
  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("Bệnh nhân hôm nay", "128", Icons.group, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard("Đang chờ khám", "32", Icons.hourglass_top, Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard("Đã khám xong", "78", Icons.check_circle, Colors.green),
            const SizedBox(width: 16),
            _buildStatCard("Doanh thu hôm nay", "12.500.000 VNĐ", Icons.monetization_on, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(Icons.list_alt, "Danh sách chờ"),
        _buildActionItem(Icons.credit_card, "Thanh toán"),
        _buildActionItem(Icons.description, "Hồ sơ bệnh án"),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: kSecondaryColor.withOpacity(0.1),
          child: Icon(icon, size: 30, color: kSecondaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: kTextColor)),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        _buildChartContainer("Số lượng bệnh nhân theo ngày", _buildPatientBarChart()),
        const SizedBox(height: 20),
        _buildChartContainer("Doanh thu theo tuần", _buildRevenueLineChart()),
        const SizedBox(height: 20),
        _buildChartContainer("Tỷ lệ khám theo chuyên khoa", _buildSpecialtyPieChart()),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 250, child: chart),
        ],
      ),
    );
  }

  Widget _buildPatientBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 130,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 30)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'T2'; break;
                  case 1: text = 'T3'; break;
                  case 2: text = 'T4'; break;
                  case 3: text = 'T5'; break;
                  case 4: text = 'T6'; break;
                  case 5: text = 'T7'; break;
                  case 6: text = 'CN'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarGroup(0, 90),
          _makeBarGroup(1, 110),
          _makeBarGroup(2, 120),
          _makeBarGroup(3, 100),
          _makeBarGroup(4, 80),
          _makeBarGroup(5, 70),
          _makeBarGroup(6, 50),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: kSecondaryColor,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueLineChart() {
    final formatCurrency = NumberFormat.compact(locale: 'vi_VN');
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 15000000,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text(formatCurrency.format(value), style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Tuần 1'; break;
                  case 1: text = 'Tuần 2'; break;
                  case 2: text = 'Tuần 3'; break;
                  case 3: text = 'Tuần 4'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 3, minY: 0, maxY: 60000000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 30000000),
              FlSpot(1, 45000000),
              FlSpot(2, 35000000),
              FlSpot(3, 50000000),
            ],
            isCurved: true,
            color: kAccentColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: kAccentColor.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyPieChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {}),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          _makePieSection(35, 'Nội khoa', Colors.blue),
          _makePieSection(25, 'Ngoại khoa', Colors.green),
          _makePieSection(20, 'Nhi khoa', Colors.orange),
          _makePieSection(12, 'Tai mũi họng', Colors.purple),
          _makePieSection(8, 'Khác', Colors.red),
        ],
      ),
    );
  }

  PieChartSectionData _makePieSection(double value, String title, Color color) {
    const radius = 60.0;
    const titleStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}%',
      radius: radius,
      titleStyle: titleStyle,
    );
  }

  Widget _buildRecentAppointments() {
    final appointments = [
      {'time': '08:00', 'name': 'Nguyễn Văn A', 'details': 'BN001 • BS. Trần Minh', 'status': 'Chờ khám', 'color': Colors.orange},
      {'time': '08:30', 'name': 'Trần Thị B', 'details': 'BN002 • BS. Lê Hương', 'status': 'Đang khám', 'color': Colors.blue},
      {'time': '09:00', 'name': 'Lê Văn C', 'details': 'BN003 • BS. Trần Minh', 'status': 'Chờ khám', 'color': Colors.orange},
      {'time': '09:30', 'name': 'Phạm Thị D', 'details': 'BN004 • BS. Nguyễn Hà', 'status': 'Hoàn thành', 'color': Colors.green},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lịch khám gần đây",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final appt = appointments[index];
              return _buildAppointmentTile(
                time: appt['time'] as String,
                name: appt['name'] as String,
                details: appt['details'] as String,
                status: appt['status'] as String,
                statusColor: appt['color'] as Color,
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentTile({
    required String time,
    required String name,
    required String details,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}