import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/models/doctor.dart';
import 'package:flutter_application_datlichkham/services/api_doctors.dart';
import 'package:flutter_application_datlichkham/services/api_service.dart';
import 'package:go_router/go_router.dart';

class FeaturedDoctors extends StatelessWidget {
  const FeaturedDoctors({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Doctor>>(
      future: DoctorService.getFeaturedDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return const Text("Không có bác sĩ");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bác sĩ nổi bật",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/doctor_list'); // 👈 route danh sách bác sĩ
                  },
                  child: const Text(
                    "Xem tất cả",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doc = doctors[index];

                  return GestureDetector(
                    onTap: () {
                      context.push('/doctor-detail/${doc.id}');
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: doc.avatar.isNotEmpty
                                ? NetworkImage(doc.avatar)
                                : null,
                            child: doc.avatar.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            doc.specialty,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "${doc.experience} năm",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "${doc.price} đ",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
