enum NotificationType { newPatient, paymentSuccess }

class AppNotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final DateTime timestamp;
  bool isUnread;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isUnread = true,
  });
}