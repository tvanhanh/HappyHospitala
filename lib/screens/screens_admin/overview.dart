import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- PALETTE MÀU SẮC (Giữ nguyên) ---
const Color primaryColor = Color(0xFF1565C0);
const Color aiAccentColor = Color(0xFFFF8F00);
const Color blockchainColor = Color(0xFF673AB7);

class DashboardOverview extends StatelessWidget {
  // Sửa lại định dạng ngày cho tiếng Việt nếu chưa cài locale thì để mặc định
  final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        // ✅ FIX 1: Giảm padding tổng thể từ 20 -> 12 để có thêm chỗ trống
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            SizedBox(height: 20),

            // --- PHẦN 1: THỐNG KÊ TỔNG QUAN ---
            Text("CHỈ SỐ HOẠT ĐỘNG CHÍNH", style: _sectionTitleStyle),
            SizedBox(height: 10),
            // ✅ FIX 2: Row chứa 3 card dễ bị tràn -> Giảm khoảng cách giữa các card
            Row(
              children: [
                _buildStatCard("Bệnh nhân", "120", Icons.people_alt_rounded,
                    Colors.blue, "+12%"),
                SizedBox(width: 8), // Giảm từ 15 -> 8
                _buildStatCard("Lịch hẹn", "24", Icons.calendar_month_rounded,
                    Colors.green, "Hôm nay"),
                SizedBox(width: 8), // Giảm từ 15 -> 8
                _buildStatCard("Bác sĩ trực", "06",
                    Icons.medical_services_rounded, Colors.blue, "Online"),
              ],
            ),
            SizedBox(height: 25),

            // --- PHẦN 2: TRUNG TÂM AI & BLOCKCHAIN ---
            Text("TRẠNG THÁI CÔNG NGHỆ LÕI", style: _sectionTitleStyle),
            SizedBox(height: 10),
            // ✅ FIX 3: IntrinsicHeight giúp 2 cột cao bằng nhau
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildAICard()),
                  SizedBox(width: 12),
                  Expanded(child: _buildBlockchainCard()),
                ],
              ),
            ),

            SizedBox(height: 25),

            // --- PHẦN 3: LỊCH TRÌNH ---
            // ✅ FIX 4: Nếu màn hình nhỏ, chuyển Row thành Column hoặc điều chỉnh flex
            // Ở đây tôi giữ Row nhưng tối ưu nội dung bên trong
            Container(
              height: 300, // Đặt chiều cao cố định hoặc dùng logic khác
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildAppointmentList(),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildDiseaseChart(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON (ĐÃ FIX) ---

  TextStyle get _sectionTitleStyle => TextStyle(
      fontSize: 13, // Giảm font size một chút
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 1.0);

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ FIX 5: Dùng Flexible để text không đẩy icon ra ngoài màn hình
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào, Admin 👋",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900),
                overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
              ),
              SizedBox(height: 4),
              Text(today,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
          child: Icon(Icons.notifications_active_outlined,
              color: primaryColor, size: 24),
        )
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtext) {
    return Expanded(
      child: Container(
        // ✅ FIX 6: Giảm padding trong Card từ 20 -> 10 hoặc 12
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 3))
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                // Value
                // ✅ FIX 7: FittedBox giúp số to tự thu nhỏ nếu hết chỗ
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Title
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            // Subtext
            Text(subtext,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildAICard() {
    return Container(
      // ✅ FIX 8: Giảm padding
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        border: Border.all(color: aiAccentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: aiAccentColor, size: 20),
              SizedBox(width: 6),
              // ✅ FIX 9: Expanded cho Title để tránh overflow
              Expanded(
                child: Text(
                  "AI Optimize",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: aiAccentColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildAIIndicator("Lịch hẹn", 0.92, "Tốt"),
          SizedBox(height: 8),
          _buildAIIndicator("Dự đoán", 0.85, "Khá"),
          SizedBox(height: 12),
          Text("Thời gian chờ giảm 15%.",
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildAIIndicator(String label, double value, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Text(status,
                style: TextStyle(
                    fontSize: 11,
                    color: aiAccentColor,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: aiAccentColor.withOpacity(0.1),
          color: aiAccentColor,
          borderRadius: BorderRadius.circular(5),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildBlockchainCard() {
    return Container(
      // ✅ FIX 10: Giảm padding
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        border: Border.all(color: blockchainColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: blockchainColor, size: 20),
              SizedBox(width: 6),
              // ✅ FIX 11: Expanded tránh tràn chữ Blockchain Security
              Expanded(
                child: Text(
                  "Blockchain",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: blockchainColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildBlockchainInfo("Mạng", "Synced", Icons.cloud_done_rounded),
          Divider(height: 12),
          _buildBlockchainInfo("Blocks", "#1.2M", Icons.layers_rounded),
          Divider(height: 12),
          _buildBlockchainInfo(
              "Pending", "0 tx", Icons.hourglass_empty_rounded),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 8),
        // ✅ FIX 12: Column bọc trong Expanded
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1),
              Text(value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentList() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Lịch sắp tới",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  "Xem tất cả",
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                )
              ],
            ),
            Divider(),
            // Danh sách cuộn được nếu quá dài
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildAppointmentTile("Nguyễn A", "10:00", "Khám TQ"),
                  _buildAppointmentTile("Trần B", "10:30", "Tiểu đường"),
                  _buildAppointmentTile("Lê C", "11:15", "Tim mạch"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTile(String name, String time, String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6)),
            child: Text(time,
                style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(reason,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseChart() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text("Nguy cơ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            // ✅ FIX 13: FittedBox cho biểu đồ
            FittedBox(
              child: SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 8,
                        color: Colors.red,
                        backgroundColor: Colors.green.shade100),
                    Text("70%",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              // Dùng Wrap thay vì Row cứng nhắc
              spacing: 8,
              children: [
                _buildLegend(Colors.red, "Cao"),
                _buildLegend(Colors.amber, "TB"),
                _buildLegend(Colors.green, "Thấp"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
