import 'package:flutter/material.dart';
class DashboardOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard("Bệnh nhân", "120", Colors.blue),
              _buildStatCard("Lịch hẹn", "20", Colors.green),
              _buildStatCard("Bác sĩ", "6", Colors.orange),
            ],
          ),
          SizedBox(height: 20),
          // Form nhập bác sĩ
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Thêm bác sĩ mới", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextField(decoration: InputDecoration(labelText: "Họ tên")),
                  TextField(decoration: InputDecoration(labelText: "Chuyên khoa")),
                  TextField(decoration: InputDecoration(labelText: "Email")),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("Lưu"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Chọn ngày thống kê", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.date_range),
                    label: Text("Chọn ngày"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(Icons.analytics, size: 32, color: color),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
