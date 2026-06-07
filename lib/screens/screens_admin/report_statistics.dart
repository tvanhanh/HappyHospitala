import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Để format tiền tệ và ngày tháng chuyên nghiệp
// import '../../services//config.dart';
// import '../../services/api_appointment.dart';

// --- PALETTE MÀU CHUYÊN NGHIỆP ---
const Color kPrimaryColor = Color(0xFF1565C0); // Xanh Admin
const Color kRevenueColor = Color(0xFF43A047); // Xanh lá (Doanh thu)
const Color kPatientColor = Color(0xFF00ACC1); // Cyan (Bệnh nhân)
const Color kAppointmentColor = Color(0xFFFB8C00); // Cam (Lịch hẹn)
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;

class MonthlyReportScreen extends StatefulWidget {
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  // DỮ LIỆU MẪU PHONG PHÚ HƠN (Thay thế bằng API thật của bạn)
  int totalPatients = 145;
  int newPatients = 45; // Bệnh nhân mới
  int totalAppointments = 180;
  int completedAppointments = 165;
  int cancelledAppointments = 15;
  double totalRevenue = 85600000;

  // Dữ liệu biểu đồ cột (Bệnh nhân theo tuần)
  final List<int> weeklyPatients = [35, 42, 30, 38];

  // Dữ liệu biểu đồ đường (Doanh thu theo tuần - Triệu VNĐ)
  final List<FlSpot> weeklyRevenueSpots = const [
    FlSpot(0, 21.5), // Tuần 1
    FlSpot(1, 25.2), // Tuần 2
    FlSpot(2, 18.8), // Tuần 3
    FlSpot(3, 20.1), // Tuần 4
  ];

  List<dynamic> appointments = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // fetchAppointmentData(); // Gọi API thật ở đây
  }

  // Future<void> fetchAppointmentData() async { ... } (Giữ nguyên logic gọi API của bạn)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Báo cáo Hoạt động Tháng ${DateTime.now().month}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              // TODO: Chức năng xuất báo cáo PDF/Excel
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đang xuất báo cáo...")));
            },
            tooltip: "Xuất báo cáo",
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. DASHBOARD TỔNG QUAN (KPIs) ---
                  Text("TỔNG QUAN HOẠT ĐỘNG", style: _sectionTitleStyle),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      _buildBigStatCard(
                          "Tổng Doanh Thu",
                          _formatCurrency(totalRevenue),
                          Icons.attach_money,
                          kRevenueColor),
                      SizedBox(width: 15),
                      _buildBigStatCard(
                          "Lịch Hẹn Hoàn Thành",
                          "$completedAppointments ca",
                          Icons.event_available,
                          kAppointmentColor),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      _buildSmallStatCard("Tổng Bệnh Nhân", "$totalPatients",
                          Icons.people_alt, kPatientColor,
                          subText: "+$newPatients mới"),
                      SizedBox(width: 15),
                      _buildSmallStatCard(
                          "Tỷ lệ Hủy Lịch",
                          "${((cancelledAppointments / totalAppointments) * 100).toStringAsFixed(1)}%",
                          Icons.event_busy,
                          Colors.redAccent),
                    ],
                  ),

                  SizedBox(height: 30),

                  // --- 2. BIỂU ĐỒ XU HƯỚNG DOANH THU (LINE CHART) ---
                  Text("XU HƯỚNG DOANH THU (TRIỆU VNĐ)",
                      style: _sectionTitleStyle),
                  SizedBox(height: 15),
                  _buildChartContainer(_buildRevenueLineChart()),

                  SizedBox(height: 30),

                  // --- 3. BIỂU ĐỒ LƯỢNG BỆNH NHÂN (BAR CHART) ---
                  Text("LƯỢNG BỆNH NHÂN THEO TUẦN", style: _sectionTitleStyle),
                  SizedBox(height: 15),
                  _buildChartContainer(_buildPatientBarChart()),
                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- CÁC WIDGET CON ---

  TextStyle get _sectionTitleStyle => TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 1.2);

  // Card thống kê lớn
  Widget _buildBigStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.trending_up,
                    color: Colors.green, size: 20), // Demo trend icon
              ],
            ),
            SizedBox(height: 15),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            SizedBox(height: 5),
            Text(title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

// Card thống kê nhỏ (Đã sửa lỗi Overflow)
  Widget _buildSmallStatCard(
      String title, String value, IconData icon, Color color,
      {String? subText}) {
    return Expanded(
      child: Container(
        // 1. Giảm padding ngang một chút (từ 20 xuống 12) để tiết kiệm diện tích
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
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
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 10), // Giảm khoảng cách từ 15 xuống 10

            // 2. QUAN TRỌNG: Bọc Column trong Expanded để tránh lỗi tràn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Value
                  Text(value,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1, // Chỉ cho phép 1 dòng
                      overflow:
                          TextOverflow.ellipsis // Nếu dài quá thì hiện dấu ...
                      ),

                  // Title
                  Text(title,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2, // Cho phép tối đa 2 dòng nếu tiêu đề dài
                      overflow: TextOverflow.ellipsis),

                  // Subtext
                  if (subText != null)
                    Text(subText,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Container bao bọc biểu đồ
  Widget _buildChartContainer(Widget chart) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: chart,
    );
  }

  // --- BIỂU ĐỒ ĐƯỜNG (Revenue Line Chart) ---
  Widget _buildRevenueLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
            show: true, drawVerticalLine: false, horizontalInterval: 5),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: _buildBottomTitles(),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}tr',
                      style: TextStyle(fontSize: 10, color: Colors.grey)))),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 3, minY: 0, maxY: 30, // Điều chỉnh theo dữ liệu thật
        lineBarsData: [
          LineChartBarData(
            spots: weeklyRevenueSpots,
            isCurved: true, // Đường cong mềm mại
            color: kRevenueColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                        radius: 5,
                        color: kRevenueColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white)),
            belowBarData: BarAreaData(
                show: true,
                color: kRevenueColor.withOpacity(0.2)), // Đổ màu dưới đường
          ),
        ],
      ),
    );
  }

  // --- BIỂU ĐỒ CỘT (Patient Bar Chart) ---
  Widget _buildPatientBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60, // Điều chỉnh theo dữ liệu thật
        barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => kPrimaryColor,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                      '${rod.toY.toInt()} người',
                      TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            )),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 10,
                  getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey)))),
          bottomTitles: _buildBottomTitles(),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        barGroups: List.generate(weeklyPatients.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weeklyPatients[index].toDouble(),
                width: 24,
                color: kPatientColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 60,
                    color: Colors.grey.shade100), // Nền cột mờ
              ),
            ],
          );
        }),
      ),
    );
  }

  AxisTitles _buildBottomTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          const weekNames = ['T1', 'T2', 'T3', 'T4'];
          if (value.toInt() >= 0 && value.toInt() < weekNames.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(weekNames[value.toInt()],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700)),
            );
          }
          return Container();
        },
        reservedSize: 30,
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(amount);
  }
}
