import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_application_datlichkham/screens/screen_authencication/login_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_authencication/register_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/doctor_search_bar.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/featured_doctors.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/patient_appointments_screen.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'faq_screen.dart';
import 'medical_facilities_screen.dart';
import 'specialties_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'discussion_screen.dart';
import 'diagnosis_result_screen.dart';
import '../screen_doctor/doctor_home_screen.dart';
import '../screens_admin/home.dart';
import 'medical_records.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  // state profile
  bool showBanner = false;
  bool isLoading = true;
  bool dismissed = false;

  @override
  void initState() {
    super.initState();
    print("INIT STATE RUNNING");
    _checkUser();
    loadProfile();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('name');
    final role = prefs.getString('role');

    if (name != null && role != null) {
      setState(() {
        _user = {
          'name': name,
          'role': role,
        };
      });
    }
  }

  Future<void> loadProfile() async {
    print("LOAD PROFILE START"); // 🔥
    final profile = await ApiService.getProfile();

    debugPrint("PROFILE: $profile");
    setState(() {
      isLoading = false;
      showBanner =
          profile['profileStatus']['isComplete'] == false && !dismissed;
    });
  }

  Future<void> _checkUser() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        _user = jsonDecode(userData);
      });
    }
    setState(() {
      _isLoading = false;
    });

    if (_user != null && _user!['role'] != 'patient') {
      if (!mounted) return;
      if (_user!['role'] == 'admin') {
        context.go('/admin');
      } else if (_user!['role'] == 'doctor') {
        context.go('/doctor');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Xóa toàn bộ session
    await prefs.clear();

    setState(() {
      _user = null;
    });

    if (context.mounted) {
      context.go('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/home/profile');
        break;
      case 2:
        context.go('/home/discussion');
        break;
      case 3:
        context.go('/home/appointments');
        break;
      case 4:
        context.go('/home/results');
        break;
      case 5:
        context.go('/patient/medical-records');
        break;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/logo.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        backgroundColor: Colors.blue,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          _user == null
              ? TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => LoginScreen(),
                    );
                  },
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Row(
                  children: [
                    Text(
                      'Xin chào, ${_user!['name'] ?? 'Người dùng'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),
        ],
      ),

      drawer: buildDrawerMenu(context),

      // 🔥 BANNER + BODY FIX Ở ĐÂY
      body: Column(
        children: [
          // 🔥 BANNER (đã fix đúng vị trí)
          if (showBanner)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Bạn chưa hoàn thiện hồ sơ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/update_profile');
                    },
                    child: Text(
                      "Cập nhật thông tin",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // 🔥 MAIN CONTENT
          Expanded(child: _buildHomeContent()),
        ],
      ),
    );
  }

  Widget buildBanner() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Hoàn thiện hồ sơ để sử dụng đầy đủ tính năng",
              style: TextStyle(color: Colors.white),
            ),
          ),
          Column(
            children: [
              // ❌ close banner
              GestureDetector(
                onTap: () {
                  setState(() {
                    showBanner = false;
                    dismissed = true;
                  });
                },
                child: Icon(Icons.close, color: Colors.white),
              ),

              SizedBox(height: 8),

              // 🔥 đi tới update profile
              ElevatedButton(
                onPressed: () {
                  context.push('/update_profile');
                },
                child: Text("Cập nhật"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                kBottomNavigationBarHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            DoctorSearchBar(
              onSearch: (keyword) {
                context.push('/doctors?search=$keyword');
              },
            ),
            SizedBox(height: 20),
            _buildCarousel(),
            SizedBox(height: 20),
            FeaturedDoctors(),
            SizedBox(height: 20),
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildBookingCard(),
            SizedBox(height: 20),
            _buildDiagnosisCard(),
            SizedBox(height: 20),
            _buildDoctorSection(),
            SizedBox(height: 20),
            _buildServiceSection(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    final List<String> images = [
      'assets/banner1.jpg',
      'assets/banner4.jpg',
      'assets/banner5.jpg',
      'assets/banner6.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: images.map((imgPath) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(imgPath),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hồ Sơ Cá Nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    _user?['name']?[0] ?? 'U',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?['name'] ?? 'Người dùng',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bệnh nhân',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.go('/patient/profile-screen');
              },
              child:
                  Text('Xem chi tiết', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.go('/home/booking');
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue, size: 30),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt Lịch Hẹn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Lên lịch khám với bác sĩ của bạn',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.go('/patient/diagnosis_result_screen');
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.blue, size: 30),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xem Kết Quả Chẩn Đoán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Kiểm tra kết quả khám bệnh của bạn',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bác sĩ nổi bật',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.go('/doctor_list');
                },
                child: Text('Xem tất cả', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.7,
          ),
          items: doctors.map((doctor) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      doctor['image']!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          doctor['name']!,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          doctor['specialty']!,
                          style: TextStyle(color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildDrawerMenu(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          _buildDrawerItem(
              context, 'Chuyên khoa', '/patient/specialties_screen'),
          _buildDrawerItem(
              context, 'Cơ sở y tế', '/patient/medical_facilities_screen'),
          _buildDrawerItem(context, 'Bác sĩ', '/patient/doctor_screen'),
          _buildDrawerItem(
              context, 'Hồ Sơ Bệnh án', '/patient/medical-records'),
          _buildDrawerItem(context, 'Hỏi đáp', '/patient/faq'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, String routePath) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      onTap: () {
        // 1. Đóng Drawer trước
        if (context.canPop()) {
          context.pop();
        }

        // 2. Chuyển trang bằng GoRouter (Dùng path)
        context.go(routePath);
      },
    );
  }

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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dịch vụ nổi bật',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.push('/doctor_list');
                },
                child: Text('Xem tất cả', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Column(
          children: services.map((service) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    service['image']!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  service['title']!,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(service['desc']!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
