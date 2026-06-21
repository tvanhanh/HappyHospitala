import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'payment_form.dart';
import 'settings_panel.dart';
import 'notification_panel.dart';
import '../../models/prescription_model.dart';
import '../../services/api_prescription.dart';
import '../../models/bill_model.dart';
import '../../services/api_bill.dart';
import 'prescription_detail_page.dart';
import '../../services/report_service.dart';
import '../../services/pay_notification_service.dart';
import '../../models/pay_notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  int activeTab = 0; // 0: Hàng đợi thanh toán, 1: Lịch sử giao dịch
  
  List<PrescriptionModel> _prescriptions = [];
  List<BillModel> _bills = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Các biến lưu số liệu thống kê thời gian thực (Real-time KPI)
  double _todayRevenue = 0;
  int _todayPaidPatientsCount = 0;
  int _todayInvoicesCount = 0;
  double _monthRevenue = 0;


  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }
  Future<Map<String, String>> _getUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  // Thay 'user_name' và 'user_role' bằng Key bạn đã lưu lúc Đăng nhập
  String name = prefs.getString('name') ?? 'Nguyễn Thị Thu'; 
  String role = prefs.getString('role') ?? 'Thu ngân';
  
  return {
    'name': name,
    'role': role,
  };
}

  // 🟢 ĐỒNG BỘ ĐIỀU HƯỚNG TẢI DỮ LIỆU ĐỘNG VÀ TÍNH TOÁN KPI THỰC TẾ
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. Luôn tải song song toàn bộ dữ liệu hóa đơn tổng để tính toán thống kê chính xác
      final allBillsResult = await ApiBill.getAllBills(page: 1, limit: 200, search: '');
      
      final DateTime now = DateTime.now();
      double tempTodayRevenue = 0;
      int tempTodayPaidCount = 0;
      int tempTodayInvoiceCount = 0;
      double tempMonthRevenue = 0;
      final notificationService = NotificationService();
      for (var bill in allBillsResult) {
        bool alreadyNotified = notificationService.notifications.any((n) => n.content.contains(bill.id ?? ''));
        if (!alreadyNotified) {
        notificationService.addNotification(
          type: NotificationType.newPatient,
          title: 'Bệnh nhân mới chờ thanh toán',
          content: '${bill.patientName} (Mã: ${bill.id}) đang chờ thanh toán.',
        );
      }
        final DateTime? billDate = bill.createdAt ?? (bill.timeArrived.isNotEmpty ? _tryParseDate(bill.timeArrived) : null);
        if (billDate == null) continue;

        double billPrice = (bill.finalTotalPrice).toDouble();

        // Kiểm tra xem hóa đơn có thuộc tháng này không
        if (billDate.year == now.year && billDate.month == now.month) {
          tempMonthRevenue += billPrice;

          // Kiểm tra xem hóa đơn có thuộc ngày hôm nay không
          if (billDate.day == now.day) {
            tempTodayRevenue += billPrice;
            tempTodayInvoiceCount++;
            tempTodayPaidCount++; // Giả định 1 hóa đơn tương ứng với 1 bệnh nhân hoàn tất thanh toán
          }
        }
      }

      // 2. Tải dữ liệu riêng biệt cho View nội dung của Tab hiện tại
      if (activeTab == 0) {
        final queueResult = await ApiPrescription.getCompletedPrescriptions();
        
        // Thực hiện lọc cục bộ nếu người dùng đang tìm kiếm trong hàng đợi
        if (_searchQuery.isNotEmpty) {
          _prescriptions = queueResult.where((p) {
            return (p.patientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   (p.patientId ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        } else {
          _prescriptions = queueResult;
        }
      } else {
        // Tải danh sách hóa đơn có bộ lọc query từ Server cho Tab Lịch sử
        _bills = await ApiBill.getAllBills(page: 1, limit: 50, search: _searchQuery);
      }

      if (mounted) {
        setState(() {
          _todayRevenue = tempTodayRevenue;
          _todayPaidPatientsCount = tempTodayPaidCount;
          _todayInvoicesCount = tempTodayInvoiceCount;
          _monthRevenue = tempMonthRevenue;
        });
      }
    } catch (e) {
      print("💥 Lỗi khi cập nhật UI CashierScreen từ API: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm bổ trợ chuyển đổi chuỗi thời gian của DB thành đối tượng DateTime để phân tích
  DateTime? _tryParseDate(String dateStr) {
    try {
      // Định dạng mẫu: "10:18 12/06/2026"
      List<String> parts = dateStr.split(' ');
      if (parts.length == 2) {
        List<String> dmy = parts[1].split('/');
        if (dmy.length == 3) {
          return DateTime(int.parse(dmy[2]), int.parse(dmy[1]), int.parse(dmy[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  // 🟢 HÀM MỞ HỘP THOẠI THANH TOÁN 
  void _openPaymentDialog(PrescriptionModel prescription) async {
    final dynamic isPaidSuccess = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 800,
            child: PaymentForm(
              prescription: prescription, 
            ),
          ),
        );
      },
    );

    if (isPaidSuccess == true) {
      _fetchData();
    }
  }

  // 🟢 HỘP THOẠI XÁC NHẬN ĐĂNG XUẤT (Chuẩn UI Hệ thống Smart Clinic)
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 10),
              Text('Xác nhận đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi Hệ thống Thu ngân không?', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Không', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Đóng alert
                // Nếu sử dụng Navigator 1.0 truyền thống:
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Có, đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  String _formatMoney(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: _buildAppBar(context),
      endDrawer: const SettingsPanel(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatGrid(),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECECEC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabSwitcher(),
                  _isLoading 
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF070412))),
                        )
                      : (activeTab == 0 ? _buildQueueView() : _buildHistoryView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: const Border(bottom: BorderSide(color: Color(0xFFECECEC), width: 1)),
    titleSpacing: 0,
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hệ thống Thu ngân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
        SizedBox(height: 2),
        Text('Phòng khám Smart Clinic', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w400)),
      ],
    ),
    actions: [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 26), 
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (context, anim1, anim2) {
                  return const Align(
                    alignment: Alignment.centerRight,
                    child: NotificationPanel(),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
                    child: child,
                  );
                },
              );
            }
          ),
          Positioned(
            top: 12,
            right: 14,
            child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
          )
        ],
      ),
      Builder(
        builder: (innerContext) {
          return IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87, size: 24),
            onPressed: () {
              Scaffold.of(innerContext).openEndDrawer();
            },
          );
        },
      ),
      const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: VerticalDivider(color: Color(0xFFE2E8F0), width: 24)),
      
      // FIX: Đã xóa chữ 'const' ở đây và loại bỏ bớt 1 tầng Column thừa
      FutureBuilder<Map<String, String>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
              ),
            );
          }
          
          final userData = snapshot.data;
          String userName = (userData?['name']?.isNotEmpty == true) ? userData!['name']! : 'Chưa đăng nhập';
          String userRole = (userData?['role']?.isNotEmpty == true) ? userData!['role']! : 'Thu ngân';

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end, // Căn lề phải cho đẹp mắt trên AppBar
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
              Text(userRole, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          );
        },
      ),
      
      const SizedBox(width: 12),
      const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFE2E8F0),
        child: Text('NT', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24), 
        onPressed: () => _showLogoutDialog(context),
      ),
      const SizedBox(width: 12),
    ],
  );
}
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Doanh thu hôm nay',
                  value: _formatMoney(_todayRevenue),
                  trend: 'Tính theo ngày hiện tại',
                  icon: const Text('\$', style: TextStyle(fontSize: 22, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Bệnh nhân đã thanh toán',
                  value: '$_todayPaidPatientsCount',
                  trend: 'Số lượng hồ sơ hoàn tất hôm nay',
                  icon: const Icon(Icons.people_alt_outlined, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24), 
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Hóa đơn đã xuất',
                  value: '$_todayInvoicesCount',
                  trend: 'Số biên lai in ra trong ngày',
                  icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Doanh thu tháng này',
                  value: _formatMoney(_monthRevenue),
                  trend: 'Cộng dồn chu kỳ tháng',
                  icon: const Icon(Icons.trending_up_rounded, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECECEC))),
      ),
      child: Row(
        children: [
          _buildSingleTab('Hàng đợi thanh toán', 0),
          _buildSingleTab('Lịch sử giao dịch', 1),
        ],
      ),
    );
  }

  Widget _buildSingleTab(String title, int index) {
    bool isActive = activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          _searchController.clear();
          setState(() {
            activeTab = index;
            _searchQuery = '';
          });
          _fetchData(); 
        },
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color.fromARGB(255, 68, 31, 199) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hàng đợi thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 4),
          Text('${_prescriptions.length} bệnh nhân đang chờ', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),

          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
              _fetchData();
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bệnh nhân đang chờ...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _fetchData();
                    })
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          if (_prescriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Hiện không có bệnh nhân nào trong hàng đợi.", style: TextStyle(color: Colors.grey))),
            ),

          ..._prescriptions.map((prescription) {
            String name = prescription.patientName ?? "Không rõ tên"; 
            String id = prescription.patientId ?? "N/A";
            String price = _formatMoney((prescription.totalPrice ?? 0).toDouble());
            int servicesCount = 0;
            int medicinesCount = prescription.medicines?.length ?? 0;
            String medsText = medicinesCount > 0 ? "$medicinesCount loại thuốc" : "Không kèm thuốc";
            List<String> tags = [prescription.diagnosis.isNotEmpty ? prescription.diagnosis : "Khám bệnh"];

            return _buildPatientCard(
              name: name,
              id: id,
              time: "Đang đợi", 
              servicesCount: servicesCount,
              medsText: medsText,
              price: price,
              tags: tags,
              onTap: () => _openPaymentDialog(prescription),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lịch sử giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Danh sách hóa đơn hệ thống (${_bills.length})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _bills.isEmpty 
    ? null // Vô hiệu hóa nút nếu danh sách rỗng chưa có dữ liệu từ API
    : () async {
        // Hiển thị một Loading chỉ báo nhanh trên SnackBar hoặc gọi trực tiếp
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Đang khởi tạo và xuất file Excel...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Gọi service xử lý xuất file từ danh sách _bills đang hiển thị
        await ReportService.exportBillsToExcel(_bills);
      },
                icon: const Icon(Icons.outbox_rounded, size: 18, color: Colors.black87),
                label: const Text('Xuất báo cáo', style: TextStyle(color: Colors.black87, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _fetchData(); 
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên bệnh nhân hoặc mã BN...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _fetchData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18, color: Colors.black87),
                label: const Text('Lọc', style: TextStyle(color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 2))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Mã HĐ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 4, child: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Mã BN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 3, child: Text('Thời gian xuất', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 3, child: Text('Phương thức', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 1, child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              ],
            ),
          ),

          if (_bills.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Không tìm thấy dữ liệu hóa đơn nào phù hợp.", style: TextStyle(color: Colors.grey))),
            ),

          ..._bills.map((bill) {
            String rawId = bill.id ?? "";
            String invoiceId = rawId.length > 6 
                ? rawId.substring(rawId.length - 6).toUpperCase() 
                : (rawId.isNotEmpty ? rawId.toUpperCase() : "HDXXXX");

            String paymentMethod = bill.paymentMethod;
            if (paymentMethod == 'paid' || paymentMethod == 'Tiền mặt') {
              paymentMethod = 'Tiền mặt';
            }

            return _buildHistoryRow(
              invoiceId: invoiceId, 
              name: bill.patientName,
              bn: bill.patientId,
              time: bill.timeArrived, 
              method: paymentMethod, 
              price: _formatMoney((bill.finalTotalPrice).toDouble()),
              methodIcon: paymentMethod == "Tiền mặt" ? Icons.payments_outlined : Icons.sync_alt_rounded,
              rawBillData: bill, // Truyền nguyên thực thể sang hàm sinh Row để map nút chi tiết
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryRow({
    required String invoiceId, required String name, required String bn, 
    required String time, required String method, required String price, 
    required IconData methodIcon, required dynamic rawBillData
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(invoiceId, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 4, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(bn, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 3, child: Text(time, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 3, child: Row(
            children: [
              Icon(methodIcon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(method, style: const TextStyle(fontSize: 14)),
            ],
          )),
          Expanded(flex: 2, child: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(flex: 2, child: Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Text('Đã thu', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          )),
          // NÚT ĐIỀU HƯỚNG XEM CHI TIẾT HÓA ĐƠN THỰC TẾ TRONG HÀNG ĐỢI LỊCH SỬ
          Expanded(
            flex: 1, 
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3EA6E9), size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionDetailPage(prescriptionData: rawBillData.toJson()),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required String name, required String id, required String time,
    required int servicesCount, required String medsText, required String price,
    required List<String> tags, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person_outline, size: 20, color: Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                const SizedBox(width: 6),
                Text('($id)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const Spacer(),
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(Icons.description_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('$servicesCount dịch vụ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  if (medsText != 'Không kèm thuốc') ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.medication_liquid_sharp, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(medsText, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Wrap(
                spacing: 8,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final Widget icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    trend!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
        ],
      ),
    );
  }
}