import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/receptionist_drawer.dart';
const kPrimaryColor = Color(0xFF0D47A1);
const kSecondaryColor = Color(0xFF1976D2);
const kBackgroundColor = Color(0xFFF5F7FA);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF333333);

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: kBackgroundColor,

        appBar: AppBar(
          title: const Text(
            "Phòng khám ABC - Hệ thống quản lý",
          ),
          backgroundColor: kPrimaryColor,
        ),

        
      drawer: const ReceptionistDrawer(
        selectedMenu: "Hồ sơ bệnh án",
      ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchBox(),

              const SizedBox(height: 20),

              _buildPatientSummary(),

              const SizedBox(height: 20),

              _buildTabs(),

              const SizedBox(height: 20),

              SizedBox(
                height: 700,
                child: TabBarView(
                  children: [
                    _buildPatientInfo(),
                    _buildVisitHistory(),
                    _buildLabResults(),
                    _buildPrescriptions(),
                    _buildImages(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: TextField(
        decoration: InputDecoration(
          hintText:
              "Tìm bệnh nhân theo mã, tên, SĐT hoặc CCCD...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: kSecondaryColor,
            child: Text(
              "NA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          const SizedBox(width: 20),

          const Expanded(
            child: Wrap(
              spacing: 30,
              runSpacing: 10,
              children: [
                Text("Mã BN: BN001"),
                Text("15/03/1985 (41 tuổi)"),
                Text("Nam"),
                Text("0905123456"),
                Text("O+"),
              ],
            ),
          ),

          Chip(
            label: const Text("Đang điều trị"),
            backgroundColor:
                Colors.green.withOpacity(0.15),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: _cardDecoration(),
      child: const TabBar(
        isScrollable: true,
        labelColor: kPrimaryColor,
        tabs: [
          Tab(text: "Thông tin bệnh nhân"),
          Tab(text: "Lịch sử khám bệnh"),
          Tab(text: "Kết quả xét nghiệm"),
          Tab(text: "Đơn thuốc"),
          Tab(text: "Hình ảnh/CDHA"),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    "CCCD/CMND",
                    "001234567890",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(
                    "Nghề nghiệp",
                    "Kỹ sư",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    "Chiều cao",
                    "175 cm",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(
                    "Cân nặng",
                    "72 kg",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    "BMI",
                    "23.5 (Bình thường)",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoCard(
                    "Huyết áp",
                    "130/85 mmHg",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Email",
              "nguyenvanan@email.com",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Địa chỉ",
              "123 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Tiền sử bệnh",
              "Tăng huyết áp (2024), Dị ứng Penicillin",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Thuốc đang dùng",
              "Amlodipine 5mg (1 viên/ngày)",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Mã thẻ BHYT",
              "HS4012000123456",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Nơi đăng ký KCB",
              "BV Chợ Rẫy",
            ),

            const SizedBox(height: 16),

            _infoCard(
              "Ngày hết hạn",
              "31/12/2026",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Ngày khám")),
          DataColumn(label: Text("Bác sĩ")),
          DataColumn(label: Text("Chẩn đoán")),
          DataColumn(label: Text("Trạng thái")),
        ],
        rows: const [
          DataRow(
            cells: [
              DataCell(Text("15/05/2026")),
              DataCell(Text("BS Trần Minh")),
              DataCell(Text("Tăng huyết áp")),
              DataCell(Text("Hoàn thành")),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text("20/04/2026")),
              DataCell(Text("BS Nguyễn Hà")),
              DataCell(Text("Khám tổng quát")),
              DataCell(Text("Hoàn thành")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabResults() {
    return Container(
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          "Danh sách kết quả xét nghiệm",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildPrescriptions() {
    return Container(
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          "Danh sách đơn thuốc",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildImages() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text("Hình ảnh"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}