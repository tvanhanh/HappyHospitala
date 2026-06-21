import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pay_notification_model.dart';
import '../../services/pay_notification_service.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  String activeFilter = 'Tất cả';
  final _notificationService = NotificationService(); // Gọi Service tập trung

  @override
  Widget build(BuildContext context) {
    // Sử dụng ListenableBuilder để tự động re-build khi Service thay đổi dữ liệu
    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, child) {
        // Lọc danh sách theo Tab
        List<AppNotificationModel> filteredNotifications = _notificationService.notifications.where((notif) {
          if (activeFilter == 'Chưa đọc') return notif.isUnread;
          return true;
        }).toList();

        return Drawer(
          width: 420,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // ================= HEADER THÔNG BÁO =================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 22),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thông báo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(
                              '${_notificationService.unreadCount} thông báo chưa đọc',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1),

              // ================= THANH BỘ LỌC =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFilterButton('Tất cả'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Chưa đọc'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _notificationService.markAllAsRead(),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text(
                        'Đánh dấu đã đọc tất cả',
                        style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= DANH SÁCH THÔNG BÁO THẬT =================
              Expanded(
                child: filteredNotifications.isEmpty
                    ? const Center(child: Text('Không có thông báo nào', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filteredNotifications.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(filteredNotifications[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(String title) {
    bool isSelected = activeFilter == title;
    return InkWell(
      onTap: () => setState(() => activeFilter = title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF070412) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotificationModel item) {
    IconData iconData = Icons.notifications_none_outlined;
    Color iconColor = const Color(0xFF1E293B);
    Color bgColor = item.isUnread ? const Color(0xFFF8FAFC) : Colors.white;

    // Đã loại bỏ cảnh báo thuốc, chỉ phân loại 2 loại thông báo của Thu ngân
    if (item.type == NotificationType.paymentSuccess) {
      iconData = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF10B981); // Màu xanh lá thành công
    }

    // Định dạng hiển thị thời gian thực tế (Ví dụ: 15:30)
    String timeString = DateFormat('HH:mm').format(item.timestamp);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    if (item.isUnread)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.content,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        if (item.isUnread)
                          TextButton(
                            onPressed: () => _notificationService.markAsRead(item.id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Đánh dấu đã đọc', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _notificationService.removeNotification(item.id),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}