import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF5F7FA);

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final user = patient['userId'] ?? {};
    final profile = user['profile'] ?? {};
    
    final avatar = profile['avatar']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'Chưa cập nhật';
    final email = user['email']?.toString() ?? 'Chưa cập nhật';

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Chi tiết Bệnh Nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(avatar, name, email),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCard1_PersonalContact(patient, profile),
                  const SizedBox(height: 16),
                  _buildCard2_ClinicalInfo(patient),
                  const SizedBox(height: 16),
                  _buildCard3_Administrative(patient),
                  const SizedBox(height: 16),
                  _buildCard4_Security(patient, context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String avatar, String name, String email) {
    return Container(
      width: double.infinity,
      color: _kPrimary,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCard1_PersonalContact(Map<String, dynamic> patientData, Map<String, dynamic> profile) {
    final dateOfBirth = patientData['dateOfBirth']?.toString() ?? profile['dateOfBirth']?.toString() ?? 'Chưa cập nhật';
    final gender = patientData['gender']?.toString() ?? profile['gender']?.toString() ?? 'Chưa cập nhật';
    final address = profile['address']?.toString() ?? 'Chưa cập nhật';
    final phone = profile['phone']?.toString() ?? 'Chưa cập nhật';
    
    final emContact = patientData['emergencyContact'] ?? {};
    final emName = emContact['name']?.toString() ?? 'Không có';
    final emPhone = emContact['phone']?.toString() ?? 'Không có';
    final emRelation = emContact['relationship']?.toString() ?? 'Không có';

    return _buildSectionCard(
      title: 'Thông tin Cá nhân & Liên hệ',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Ngày sinh', dateOfBirth),
        _buildInfoRow('Giới tính', gender),
        _buildInfoRow('Điện thoại', phone),
        _buildInfoRow('Địa chỉ', address),
        const Divider(height: 24),
        const Text('Liên hệ Khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 8),
        _buildInfoRow('Họ tên', emName),
        _buildInfoRow('Điện thoại', emPhone),
        _buildInfoRow('Quan hệ', emRelation),
      ],
    );
  }

  Widget _buildCard2_ClinicalInfo(Map<String, dynamic> patientData) {
    final bloodType = patientData['bloodType']?.toString() ?? 'Chưa cập nhật';
    final allergies = (patientData['allergies'] as List?)?.join(', ') ?? 'Không có';
    final chronicDiseases = (patientData['chronicDiseases'] as List?)?.join(', ') ?? 'Không có';

    return _buildSectionCard(
      title: 'Thông tin Lâm sàng',
      icon: Icons.medical_services_outlined,
      children: [
        _buildInfoRow('Nhóm máu', bloodType),
        _buildInfoRow('Dị ứng', allergies.isEmpty ? 'Không có' : allergies),
        _buildInfoRow('Bệnh mãn tính', chronicDiseases.isEmpty ? 'Không có' : chronicDiseases),
      ],
    );
  }

  Widget _buildCard3_Administrative(Map<String, dynamic> patientData) {
    final identityCard = patientData['identityCard']?.toString() ?? 'Chưa cập nhật';
    final healthInsurance = patientData['healthInsurance']?.toString() ?? 'Chưa cập nhật';

    return _buildSectionCard(
      title: 'Hành chính',
      icon: Icons.badge_outlined,
      children: [
        _buildInfoRow('CCCD/CMND', identityCard),
        _buildInfoRow('BHYT', healthInsurance),
      ],
    );
  }

  Widget _buildCard4_Security(Map<String, dynamic> patientData, BuildContext context) {
    final walletAddress = patientData['walletAddress']?.toString() ?? 'Chưa thiết lập';

    return _buildSectionCard(
      title: 'Bảo mật (Blockchain)',
      icon: Icons.security,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Địa chỉ Ví (Wallet)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    walletAddress,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (walletAddress != 'Chưa thiết lập')
              IconButton(
                icon: const Icon(Icons.copy, color: _kPrimary, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: walletAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép địa chỉ ví')),
                  );
                },
              )
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kPrimary, size: 22),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
