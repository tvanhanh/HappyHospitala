import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../screens/doctors_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/patients_screen.dart';
import '../screens/medical_facilities_screen.dart';
import '../screens/specialties_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<String> images = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: buildDrawerMenu(context), // Thêm Drawer vào Scaffold,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CarouselSlider(
              options: CarouselOptions(height: 300, autoPlay: true),
              items: images.map((imgPath) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imgPath),
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            _buildDoctorSection(),
            _buildServiceSection(),
            Footer(),
          ],
        ),
      ),
    );
  }

  /// Phần danh sách bác sĩ nổi bật
  Widget _buildDoctorSection() {
    final List<Map<String, String>> doctors = [
      {
        'name': 'GS. Lê Đăng Quân',
        'specialty': 'Tim mạch',
        'image': 'assets/doctor1.jpg'
      },
      {
        'name': 'TS. Nguyễn Thị Thanh Nhàn',
        'specialty': 'Nhi khoa',
        'image': 'assets/doctor2.jpg'
      },
      {
        'name': 'TTƯT. Tú Khắc',
        'specialty': 'Thần kinh',
        'image': 'assets/doctor3.jpg'
      },
    ];

    return Column(
      children: [
        Text('Bác sĩ nổi bật',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        CarouselSlider(
          options: CarouselOptions(height: 200, autoPlay: true),
          items: doctors.map((doctor) {
            return Card(
              child: Column(
                children: [
                  Image.asset(doctor['image']!, height: 100, fit: BoxFit.cover),
                  SizedBox(height: 10),
                  Text(doctor['name']!,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(doctor['specialty']!,
                      style: TextStyle(color: Colors.blue)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// **Hàm tạo Drawer menu**
  Widget buildDrawerMenu(
    BuildContext context,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Center(
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          _buildDrawerItem(context, 'Chuyên khoa', SpecialtiesScreen()),
          _buildDrawerItem(context, 'Cơ sở y tế', MedicalFacilitiesScreen()),
          _buildDrawerItem(context, 'Bác sĩ', DoctorsScreen()),
          _buildDrawerItem(context, 'Hỏi đáp', FAQScreen()),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, Widget screen) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 18)),
      onTap: () {
        Navigator.pop(context); // Đóng Drawer trước khi chuyển trang
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen), // ✅ Chuyển trang
        );
      },
    );
  }

  /// Phần dịch vụ nổi bật
  Widget _buildServiceSection() {
    final List<Map<String, String>> services = [
      {
        'title': 'Khám tổng quát',
        'desc': 'Kiểm tra sức khỏe toàn diện',
        'image': 'assets/khamtongquat.jpg'
      },
      {
        'title': 'Xét nghiệm máu',
        'desc': 'Kiểm tra chỉ số đường huyết',
        'image': 'assets/xetnghiemmau.jpg'
      },
    ];

    return Column(
      children: [
        Text('Dịch vụ nổi bật',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Column(
          children: services.map((service) {
            return Card(
              child: ListTile(
                leading: Image.asset(service['image']!,
                    width: 50, height: 50, fit: BoxFit.cover),
                title: Text(service['title']!),
                subtitle: Text(service['desc']!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
