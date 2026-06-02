import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/receptionist_drawer.dart';
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final notifications = [
    {
      "icon": Icons.notifications,
      "title": "Bệnh nhân Nguyễn Văn A đã tới",
      "time": "2 phút trước",
      "unread": true,
    },
    {
      "icon": Icons.check_box,
      "title": "Bác sĩ Minh hoàn thành khám BN002",
      "time": "15 phút trước",
      "unread": true,
    },
    {
      "icon": Icons.calendar_month,
      "title": "Có lịch hẹn mới từ Trần Thị B",
      "time": "1 giờ trước",
      "unread": false,
    },
    {
      "icon": Icons.payments,
      "title": "Thanh toán hóa đơn #INV-001 thành công",
      "time": "2 giờ trước",
      "unread": false,
    }
  ];

  static const Color kPrimaryColor = Color(0xFF0D47A1);
  static const Color kSecondaryColor = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          "Phòng khám ABC - Hệ thống quản lý",
        ),
      ),

     drawer: const ReceptionistDrawer(
        selectedMenu: "Thông báo",
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      "Thông báo",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 8),

    Text(
      "3 thông báo chưa đọc",
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 16,
      ),
    ),
  ],
),

            const SizedBox(height: 24),

           Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Text(
        "Tất cả (10)",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    const SizedBox(width: 12),

    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Text(
        "Chưa đọc (3)",
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    const Spacer(),

    TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.done_all),
      label: const Text(
        "Đánh dấu tất cả đã đọc",
      ),
    ),
  ],
),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: item["unread"] == true
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              item["icon"] as IconData,
                              color: Colors.blue,
                            ),
                          ),

                          const SizedBox(width: 20),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"].toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item["time"].toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (item["unread"] == true)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
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
        ),
      ),
    );
  }
}

  