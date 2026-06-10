import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/receptionist_provider.dart';
import '../../services/socket_service.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  static const Color kPrimaryColor = Color(0xFF0D47A1);
  static const Color kSecondaryColor = Color(0xFF1976D2);
  bool _showOnlyUnread = false;
  Function(dynamic)? _notificationCallback;

  @override
  void initState() {
    super.initState();
    // Fetch today's appointments on screen load to refresh the events list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = ref.read(receptionistProvider).selectedDate;
      ref.read(receptionistProvider.notifier).fetchAppointments(selectedDate);
    });

    _notificationCallback = (data) {
      if (mounted) {
        final Map<String, dynamic> notification = Map<String, dynamic>.from(data);
        final title = notification['title'] ?? 'Thông báo';
        final body = notification['body'] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
        final selectedDate = ref.read(receptionistProvider).selectedDate;
        ref.read(receptionistProvider.notifier).fetchAppointments(selectedDate);
      }
    };
    SocketService.instance.on(SocketEvents.newNotification, _notificationCallback!);
  }

  @override
  void dispose() {
    if (_notificationCallback != null) {
      SocketService.instance.off(SocketEvents.newNotification, _notificationCallback);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receptionistProvider);

    // Build notifications dynamically from real today's appointments
    final List<Map<String, dynamic>> dynamicNotifications = [];

    for (var appt in state.appointments) {
      final shortId = appt.id.length > 6
          ? appt.id.substring(appt.id.length - 6).toUpperCase()
          : appt.id.toUpperCase();

      if (appt.status == 'pending') {
        dynamicNotifications.add({
          "id": "${appt.id}_pending",
          "icon": Icons.calendar_today_outlined,
          "color": Colors.orange,
          "title": "Yêu cầu đăng ký lịch mới",
          "body": "Bệnh nhân ${appt.patientName} đã gửi yêu cầu đặt lịch khám lúc ${appt.time} (#$shortId).",
          "time": "Chờ duyệt",
          "unread": true,
        });
      } else if (appt.status == 'confirmed') {
        dynamicNotifications.add({
          "id": "${appt.id}_confirmed",
          "icon": Icons.check_circle_outline,
          "color": Colors.blue,
          "title": "Lịch hẹn đã xác nhận",
          "body": "Lịch hẹn khám lúc ${appt.time} của bệnh nhân ${appt.patientName} đã được phê duyệt thành công (#$shortId).",
          "time": "Hôm nay",
          "unread": false,
        });
      } else if (appt.status == 'checked_in') {
        dynamicNotifications.add({
          "id": "${appt.id}_checked_in",
          "icon": Icons.verified_user_outlined,
          "color": Colors.green,
          "title": "Bệnh nhân đã Check-in",
          "body": "Bệnh nhân ${appt.patientName} (#$shortId) đã có mặt và được xếp vào hàng chờ khám của Bác sĩ ${appt.doctorName}.",
          "time": "Đang chờ khám",
          "unread": true,
        });
      } else if (appt.status == 'completed') {
        dynamicNotifications.add({
          "id": "${appt.id}_completed",
          "icon": Icons.assignment_turned_in_outlined,
          "color": Colors.teal,
          "title": "Ca khám hoàn thành",
          "body": "Bác sĩ ${appt.doctorName} đã hoàn thành khám và chỉ định thuốc cho bệnh nhân ${appt.patientName} (#$shortId).",
          "time": "Đã khám xong",
          "unread": false,
        });
      } else if (appt.status == 'cancelled') {
        dynamicNotifications.add({
          "id": "${appt.id}_cancelled",
          "icon": Icons.cancel_outlined,
          "color": Colors.red,
          "title": "Lịch hẹn đã bị hủy",
          "body": "Lịch khám lúc ${appt.time} của bệnh nhân ${appt.patientName} (#$shortId) đã bị hủy.",
          "time": "Đã hủy",
          "unread": false,
        });
      }
    }

    // Filter notifications based on "unread" toggle button
    final displayNotifications = _showOnlyUnread
        ? dynamicNotifications.where((n) => n["unread"] == true).toList()
        : dynamicNotifications;

    final unreadCount = dynamicNotifications.where((n) => n["unread"] == true).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: const Text(
          "Phòng khám ABC - Hệ thống quản lý",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
            },
          ),
        ],
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
                  "Thông báo sự kiện",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$unreadCount thông báo quan trọng cần lưu ý ngày hôm nay",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab toggles for filtering notifications
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOnlyUnread = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: !_showOnlyUnread ? kSecondaryColor : Colors.white,
                      border: Border.all(color: !_showOnlyUnread ? kSecondaryColor : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Tất cả (${dynamicNotifications.length})",
                      style: TextStyle(
                        color: !_showOnlyUnread ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOnlyUnread = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: _showOnlyUnread ? kSecondaryColor : Colors.white,
                      border: Border.all(color: _showOnlyUnread ? kSecondaryColor : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Chờ xử lý ($unreadCount)",
                      style: TextStyle(
                        color: _showOnlyUnread ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Refresh
                    ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
                  },
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text("Làm mới ngay"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notifications List
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayNotifications.isEmpty
                      ? _buildEmptyNotifications()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayNotifications.length,
                          itemBuilder: (context, index) {
                            final item = displayNotifications[index];
                            final Color cardColor = item["unread"] == true ? Colors.white : Colors.grey.shade50;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 0,
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: item["unread"] == true
                                      ? item["color"].withOpacity(0.4)
                                      : Colors.grey.shade200,
                                  width: item["unread"] == true ? 1.5 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: item["color"].withOpacity(0.1),
                                      child: Icon(
                                        item["icon"] as IconData,
                                        color: item["color"] as Color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item["title"].toString(),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: item["color"].withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item["time"].toString(),
                                                  style: TextStyle(
                                                    color: item["color"] as Color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item["body"].toString(),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
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

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Không có thông báo mới",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread ? "Hiện không có thông báo chờ xử lý nào." : "Mọi lịch khám hôm nay đang hoạt động bình thường.",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}