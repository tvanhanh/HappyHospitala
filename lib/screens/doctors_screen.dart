import 'package:flutter/material.dart';
import '../widgets/doctor_card.dart';
import '../models/doctor.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatelessWidget {
  final List<Doctor> doctors = [
    Doctor(
      name: 'GS. Lê Đăng Quân',
      specialty: 'Tim mạch, Xương khớp',
      imageUrl: 'assets/doctor1.jpg',
      hospital: 'Bệnh viện Bạch Mai',
      experience: 20,
      description:
          'Chuyên gia hàng đầu về Tim mạch, có hơn 20 năm kinh nghiệm.',
      phone: '0987 654 321',
      email: 'dangquan@hospital.com',
      address: '78 Giải Phóng, Hà Nội',
      workingHours: 'Thứ 2 - Thứ 7 (08:00 - 17:00)',
      bookingLink:
          'https://docs.google.com/forms/d/e/1FAIpQLScIarmuf-ne4IcJy6KLP_qUFPWuJO6vSW9F7_tyZlycLbbIYw/viewform', // Link Google Form
    ),
    Doctor(
      name: 'TS. Nguyễn Thị Thanh Nhàn',
      specialty: 'Nhi khoa, Viêm gan',
      imageUrl: 'assets/doctor2.jpg',
      hospital: 'Bệnh viện Nhi Trung ương',
      experience: 15,
      description: 'Chuyên khám bệnh cho trẻ em với hơn 15 năm kinh nghiệm.',
      phone: '0976 543 210',
      email: 'nthnhan@hospital.com',
      address: '879 La Thành, Hà Nội',
      workingHours: 'Thứ 2 - Thứ 6 (09:00 - 18:00)',
      bookingLink:
          'https://docs.google.com/forms/d/e/1FAIpQLScIarmuf-ne4IcJy6KLP_qUFPWuJO6vSW9F7_tyZlycLbbIYw/viewform',
    ),
    Doctor(
      name: 'TTƯT. Tú Khắc',
      specialty: 'Thần kinh, Nội khoa',
      imageUrl: 'assets/doctor3.jpg',
      hospital: 'Bệnh viện Chợ Rẫy',
      experience: 18,
      description: 'Bác sĩ chuyên khoa thần kinh với hơn 18 năm kinh nghiệm.',
      phone: '0934 567 890',
      email: 'tukhac@hospital.com',
      address: '201B Nguyễn Chí Thanh, TP. HCM',
      workingHours: 'Thứ 3 - Thứ 7 (07:30 - 16:30)',
      bookingLink:
          'https://docs.google.com/forms/d/e/1FAIpQLScIarmuf-ne4IcJy6KLP_qUFPWuJO6vSW9F7_tyZlycLbbIYw/viewform',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách bác sĩ')),
      body: ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DoctorDetailScreen(doctor: doctors[index]),
                ),
              );
            },
            child: DoctorCard(doctor: doctors[index]),
          );
        },
      ),
    );
  }
}
