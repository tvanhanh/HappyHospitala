import 'package:flutter/material.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            doctor.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover, // ✅ Giữ tỉ lệ ảnh
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: 50, color: Colors.blue);
            },
          ),
        ),
        title: Text(doctor.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(doctor.specialty, style: TextStyle(color: Colors.blue)),
      ),
    );
  }
}
