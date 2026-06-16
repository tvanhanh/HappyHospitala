import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF5F7FA);

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Hàm fomat ngày tháng nhanh không cần thư viện ngoài
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Chưa cập nhật';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    final avatar = patient['avatar']?.toString() ?? '';
    final name = patient['fullName']?.toString() ?? 'Chưa cập nhật';
    final email = patient['email']?.toString() ?? 'Chưa cập nhật';
    final phone = patient['phoneNumber']?.toString() ?? 'Chưa cập nhật';
    final status = patient['status']?.toString() ?? '';
    final isLocked = status == 'inactive';

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Hồ Sơ Bệnh Nhân',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút khóa/mở khóa tài khoản cho Admin
          IconButton(
            tooltip: isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
            icon: Icon(isLocked ? Icons.lock : Icons.lock_open,
                color: isLocked ? Colors.orange : Colors.white),
            onPressed: () {
              // TODO: Gọi API khóa/mở khóa tài khoản
            },
          )
        ],
      ),
      body: Column(
        children: [
          // ================= 1. HEADER NHẬN DIỆN =================
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                            fontSize: 14, color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLocked ? 'Đã khóa' : 'Đang hoạt động',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.call,
                                size: 16, color: Colors.white),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= 2. TAB MENU =================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _kPrimary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Hành chính"),
                Tab(text: "Lịch hẹn"),
                Tab(text: "Bệnh án (EMR)"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= 3. TAB CONTENT =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(patient),
                _buildAppointmentsTab(patient['_id']),
                _buildMedicalRecordsTab(patient['_id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: THÔNG TIN HÀNH CHÍNH ---
  Widget _buildInfoTab(Map<String, dynamic> patient) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildInfoCard(
          title: "Thông tin cá nhân",
          children: [
            _buildInfoRow(
                Icons.cake, "Ngày sinh", _formatDate(patient['dateOfBirth'])),
            _buildInfoRow(
                Icons.wc, "Giới tính", patient['gender'] ?? 'Chưa cập nhật'),
            _buildInfoRow(
                Icons.badge, "CCCD / CMND", patient['cccd'] ?? 'Chưa cập nhật'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: "Thông tin liên lạc",
          children: [
            _buildInfoRow(Icons.phone, "Số điện thoại",
                patient['phoneNumber'] ?? 'Chưa cập nhật'),
            _buildInfoRow(
                Icons.email, "Email", patient['email'] ?? 'Chưa cập nhật'),
            _buildInfoRow(Icons.location_on, "Địa chỉ",
                patient['address'] ?? 'Chưa cập nhật'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: "Thông tin hệ thống",
          children: [
            _buildInfoRow(Icons.calendar_today, "Ngày tạo tài khoản",
                _formatDate(patient['createdAt'])),
            _buildInfoRow(Icons.update, "Cập nhật lần cuối",
                _formatDate(patient['updatedAt'])),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: LỊCH HẸN (UI Placeholder) ---
  Widget _buildAppointmentsTab(String? patientId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Danh sách lịch hẹn",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text("Sau này gọi API lấy danh sách Lịch hẹn của ID:\n$patientId",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- TAB 3: BỆNH ÁN ĐIỆN TỬ (UI Placeholder) ---
  Widget _buildMedicalRecordsTab(String? patientId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Hồ sơ Bệnh án & Blockchain",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
              "Nơi hiển thị chẩn đoán, toa thuốc\nvà mã Hash xác thực của bệnh nhân $patientId",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- COMPONENT HELPERS ---
  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
