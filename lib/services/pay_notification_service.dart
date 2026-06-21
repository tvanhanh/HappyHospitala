import 'package:flutter/material.dart';
import '../models/pay_notification_model.dart';

class NotificationService extends ChangeNotifier {
  // Singleton Pattern để gọi ở bất kỳ đâu trong app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotificationModel> _notifications = [];

  List<AppNotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  /// Thêm một thông báo mới (Được gọi từ màn hình thu ngân/API)
  void addNotification({
    required NotificationType type,
    required String title,
    required String content,
  }) {
    final newNotif = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      content: content,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newNotif); // Đẩy thông báo mới lên đầu danh sách
    notifyListeners(); // Cập nhật UI ngay lập tức
  }

  /// Đánh dấu một thông báo đã đọc
  void markAsRead(String id) {
    int index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isUnread = false;
      notifyListeners();
    }
  }

  /// Đánh dấu đã đọc toàn bộ
  void markAllAsRead() {
    for (var notif in _notifications) {
      notif.isUnread = false;
    }
    notifyListeners();
  }

  /// Xóa một thông báo
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}