import 'package:flutter/material.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  String activeFilter = 'Tất cả'; // 'Tất cả' hoặc 'Chưa đọc'

  // Giả lập danh sách dữ liệu thông báo thực tế từ hình ảnh
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'new_patient',
      'title': 'Bệnh nhân mới chờ thanh toán',
      'content': 'Nguyễn Văn An (BN001) đang chờ thanh toán - 450.000đ',
      'time': '2 phút trước',
      'isUnread': true,
    },
    {
      'id': '2',
      'type': 'success',
      'title': 'Thanh toán thành công',
      'content': 'Đã hoàn tất thanh toán cho Trần Thị Bình (BN002) - 678.000đ',
      'time': '15 phút trước',
      'isUnread': true,
    },
    {
      'id': '3',
      'type': 'warning',
      'title': 'Cảnh báo tồn kho thuốc',
      'content': 'Paracetamol 500mg sắp hết - Còn 50 viên',
      'time': '1 giờ trước',
      'isUnread': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách thông báo dựa trên tab đang chọn
    List<Map<String, dynamic>> filteredNotifications = _notifications.where((notif) {
      if (activeFilter == 'Chưa đọc') return notif['isUnread'] == true;
      return true;
    }).toList();

    return Drawer(
      width: 420, // Độ rộng hợp lý cho một thanh thông báo bên cạnh màn hình
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
                          '${_notifications.where((n) => n['isUnread']).length} thông báo chưa đọc',
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

          // ================= THANH BỘ LỌC & ĐÁNH DẤU ĐÃ ĐỌC =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Các nút bộ lọc: Tất cả / Chưa đọc
                Row(
                  children: [
                    _buildFilterButton('Tất cả'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Chưa đọc'),
                  ],
                ),
                // Nút Đánh dấu đã đọc tất cả
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var notif in _notifications) {
                        notif['isUnread'] = false;
                      }
                    });
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text(
                    'Đánh dấu đã đọc tất cả',
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // ================= DANH SÁCH THÔNG BÁO =================
          Expanded(
            child: filteredNotifications.isEmpty
                ? const Center(child: Text('Không có thông báo nào', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];
                      return _buildNotificationItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget nút bấm bộ lọc đầu trang
  Widget _buildFilterButton(String title) {
    bool isSelected = activeFilter == title;
    return InkWell(
      onTap: () => setState(() => activeFilter = title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF070412) : const Color(0xFFF1F5F9), // Màu nền đen đặc trưng hoặc xám nhạt
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

  // Widget từng dòng thông báo chi tiết
  Widget _buildNotificationItem(Map<String, dynamic> item) {
    IconData iconData = Icons.notifications_none_outlined;
    Color iconColor = Colors.grey;
    Color bgColor = item['isUnread'] ? const Color(0xFFF8FAFC) : Colors.white; // Đổ nền xám nhạt nếu chưa đọc

    // Phân loại Icon và Màu sắc dựa theo type
    if (item['type'] == 'new_patient') {
      iconData = Icons.notifications_none_outlined;
      iconColor = const Color(0xFF1E293B);
    } else if (item['type'] == 'success') {
      iconData = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF10B981); // Màu xanh thành công
    } else if (item['type'] == 'warning') {
      iconData = Icons.error_outline_rounded;
      iconColor = const Color(0xFFEF4444); // Màu đỏ cảnh báo
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon phân loại thông báo
          Icon(iconData, color: iconColor, size: 22),
          const SizedBox(width: 12),

          // Nội dung text chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    // Chấm đen nhỏ biểu thị trạng thái chưa đọc ở góc phải
                    if (item['isUnread'])
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
                  item['content'],
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 8),
                
                // Hàng thao tác dưới cùng (Thời gian, Đánh dấu đọc, Xóa)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(item['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        // Nút Đánh dấu đã đọc
                        if (item['isUnread'])
                          TextButton(
                            onPressed: () {
                              setState(() {
                                item['isUnread'] = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Đánh dấu đã đọc', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        // Nút Thùng rác để xóa thông báo
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _notifications.removeWhere((n) => n['id'] == item['id']);
                            });
                          },
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