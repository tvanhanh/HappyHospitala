import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyReportScreen extends StatefulWidget {
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final int totalPatients = 120;
  final int totalAppointments = 95;
  final double totalRevenue = 35600000;
  final List<int> weeklyPatients = [30, 25, 35, 30]; // Tuần 1 -> 4

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo cáo & Thống kê tháng'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(
              title: 'Tổng số bệnh nhân',
              value: '$totalPatients người',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildSummaryCard(
              title: 'Tổng doanh thu',
              value: _formatCurrency(totalRevenue),
              icon: Icons.attach_money,
              color: Colors.green,
            ),
            _buildSummaryCard(
              title: 'Lịch hẹn đã hoàn thành',
              value: '$totalAppointments ca',
              icon: Icons.calendar_today,
              color: Colors.purple,
            ),
            SizedBox(height: 24),
            Text(
              'Số lượng bệnh nhân theo tuần',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 250, child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )} VNĐ';
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 50,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 10,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekNames = ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(weekNames[value.toInt()],
                      style: TextStyle(fontSize: 12)),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(weeklyPatients.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weeklyPatients[index].toDouble(),
                width: 22,
                color: Colors.teal,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
