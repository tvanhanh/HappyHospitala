import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../models/prescription_model.dart';
import '../../services/api_inventory.dart';
import '../../services/api_medicine.dart';
import '../../services/api_prescription.dart';

// ĐỊNH NGHĨA CÁC NHÓM THÔNG BÁO
enum NotificationType { pendingPrescription, stockAlert, expired, nearExpiry }

class PharmaNotification {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final DateTime timestamp;

  PharmaNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });
}

class PharmaNotificationBell extends StatefulWidget {
  const PharmaNotificationBell({super.key});

  @override
  State<PharmaNotificationBell> createState() => _PharmaNotificationBellState();
}

class _PharmaNotificationBellState extends State<PharmaNotificationBell> {
  List<PharmaNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Lấy dữ liệu từ các API, phân tích logic real-time và gom nhóm thông báo
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Gọi song song các dịch vụ API của hệ thống
      final futures = await Future.wait([
        ApiInventory.getInventories(),
        ApiMedicine.getAllMedicines(),
        ApiPrescription.getPendingPrescriptions(),
      ]);

      List<InventoryModel> allInventories = futures[0] as List<InventoryModel>;
      dynamic rawMedicines = futures[1];
      List<PrescriptionModel> allPrescriptions = futures[2] as List<PrescriptionModel>;

      // Map danh mục thuốc gốc để tra cứu thông tin minStock và unit O(1)
      Map<String, dynamic> medicineMap = {};
      if (rawMedicines != null) {
        for (var med in rawMedicines) {
          final String medId = med.id ?? med.idObj ?? '';
          if (medId.isNotEmpty) medicineMap[medId] = med;
        }
      }

      List<PharmaNotification> tempNotifications = [];
      final DateTime now = DateTime.now();
      final DateTime oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);

      // 1. LỌC ĐƠN THUỐC CHỜ DUYỆT (PENDING)
      for (var prescription in allPrescriptions) {
        if (prescription.status.toLowerCase().trim() == 'pending') {
          tempNotifications.add(PharmaNotification(
            id: 'pres_${prescription.id}',
            title: '📜 Đơn thuốc mới chờ duyệt',
            subtitle: 'Bệnh nhân: ${prescription.patientName} đang đợi cấp phát thuốc.',
            type: NotificationType.pendingPrescription,
            timestamp: prescription.createdAt ?? now,
          ));
        }
      }

      // 2. LỌC THUỐC TRONG KHO (HẾT HÀNG, SẮP HẾT, HẾT HẠN, CẬN HẠN TRƯỚC 1 THÁNG)
      for (var inv in allInventories) {
        final String targetMedId = inv.medicineId.toString();
        dynamic originalMedicine = medicineMap[targetMedId];

        int minStock = originalMedicine != null ? (originalMedicine.minStock ?? 0) : inv.minStock;
        String unit = originalMedicine != null ? (originalMedicine.unit ?? 'đơn vị') : 'đơn vị';

        // A. Kiểm tra Hạn sử dụng (HSD) thực tế
        if (inv.expiryDate != null) {
          if (inv.expiryDate!.isBefore(now)) {
            tempNotifications.add(PharmaNotification(
              id: 'exp_dead_${inv.id}',
              title: '🚨 Lô thuốc đã HẾT HẠN!',
              subtitle: '${inv.medicineName} (Lô: ${inv.batchNumber}) đã quá hạn sử dụng, cần làm thủ tục hủy thuốc!',
              type: NotificationType.expired,
              timestamp: now,
            ));
          } else if (inv.expiryDate!.isBefore(oneMonthFromNow)) {
            int daysLeft = inv.expiryDate!.difference(now).inDays;
            tempNotifications.add(PharmaNotification(
              id: 'exp_near_${inv.id}',
              title: '⏳ Cảnh báo cận hạn (HSD < 30 ngày)',
              subtitle: '${inv.medicineName} (Lô: ${inv.batchNumber}) còn $daysLeft ngày là hết hạn.',
              type: NotificationType.nearExpiry,
              timestamp: now,
            ));
          }
        }

        // B. Kiểm tra Định mức số lượng tồn kho theo yêu cầu logic (currentQuantity < minStock + 5)
        if (inv.currentQuantity == 0) {
          tempNotifications.add(PharmaNotification(
            id: 'stock_empty_${inv.id}',
            title: '🔴 Thuốc đã hết sạch hàng',
            subtitle: 'Mặt hàng ${inv.medicineName} trong kho hiện tại đã chạm mốc số lượng bằng 0.',
            type: NotificationType.stockAlert,
            timestamp: now,
          ));
        } else if (inv.currentQuantity < (minStock + 5)) {
          tempNotifications.add(PharmaNotification(
            id: 'stock_low_${inv.id}',
            title: '⚠ Số lượng tồn kho sắp hết',
            subtitle: '${inv.medicineName} chỉ còn tồn ${inv.currentQuantity} $unit (Ngưỡng an toàn: < ${minStock + 5}).',
            type: NotificationType.stockAlert,
            timestamp: now,
          ));
        }
      }

      // Sắp xếp thông báo: Cái nào mới xuất hiện đưa lên trên cùng
      tempNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _notifications = tempNotifications;
          _unreadCount = tempNotifications.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("💥 Lỗi nạp dữ liệu trung tâm thông báo: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 26),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
        ],
      ),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
      onSelected: (value) {
        if (value == 'REFRESH_ACTION') _loadNotifications();
      },
      itemBuilder: (BuildContext context) {
        return [
          // HEADER PANEL THÔNG BÁO
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              width: 380,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thông báo hệ thống ($_unreadCount)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                  ),
                  Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: _loadNotifications,
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _unreadCount = 0),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text('Đã đọc tất cả', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),

          // NỘI DUNG THÔNG BÁO ĐỘNG
          if (_notifications.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: SizedBox(
                height: 80,
                child: Center(
                  child: Text('🎉 Nhà thuốc vận hành an toàn! Không có cảnh báo.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ),
              ),
            )
          else
            ..._notifications.map((noti) {
              Color iconBg;
              Color iconColor;
              IconData iconData;

              switch (noti.type) {
                case NotificationType.pendingPrescription:
                  iconBg = const Color(0xFFEFF6FF); iconColor = const Color(0xFF3EA6E9); iconData = Icons.description_outlined;
                  break;
                case NotificationType.stockAlert:
                  iconBg = const Color(0xFFFFFBEB); iconColor = const Color(0xFFF59E0B); iconData = Icons.warning_amber_rounded;
                  break;
                case NotificationType.expired:
                  iconBg = const Color(0xFFFEF2F2); iconColor = const Color(0xFFEF4444); iconData = Icons.gavel_rounded;
                  break;
                case NotificationType.nearExpiry:
                  iconBg = const Color(0xFFF0FDF4); iconColor = const Color(0xFF22C55E); iconData = Icons.hourglass_bottom_rounded;
                  break;
              }

              return PopupMenuItem<String>(
                value: noti.id,
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: Icon(iconData, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(noti.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text(noti.subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ];
      },
    );
  }
}