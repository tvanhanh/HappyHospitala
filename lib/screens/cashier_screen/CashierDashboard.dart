import 'package:flutter/material.dart';
import 'payment_form.dart';
import 'settings_panel.dart';
import 'notification_panel.dart';

void main() {
  runApp(const HoaBinhApp());
}

class HoaBinhApp extends StatelessWidget {
  const HoaBinhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const CashierScreen(),
    );
  }
}

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}
class _CashierScreenState extends State<CashierScreen> {
  int activeTab = 0; // 0: Hàng đợi thanh toán, 1: Lịch sử giao dịch
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // Nền xám nhạt tinh tế
      appBar: _buildAppBar(context),
      
      endDrawer: const SettingsPanel(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= KHỐI THỐNG KÊ (THON GỌN) =================
            _buildStatGrid(),
            const SizedBox(height: 32),

            // ================= CONTAINER CHỨA TABS & NỘI DUNG =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECECEC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THANH ĐIỀU HƯỚNG TABS
                  _buildTabSwitcher(),

                  // 2. PHẦN NỘI DUNG THAY ĐỔI DỰA TRÊN TAB CHỌN
                  activeTab == 0 ? _buildQueueView() : _buildHistoryView(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Nút hỏi chấm cố định góc dưới phải

    );
  }

  // ================= THIẾT KẾ APPBAR CHUẨN (ĐÃ SỬA THAM SỐ) =================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(bottom: BorderSide(color: Color(0xFFECECEC), width: 1)),
      leading: const Icon(Icons.menu, color: Colors.black87),
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
       // Tại vị trí nút Stack chứa biểu tượng Chuông thông báo trong actions của AppBar:
Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 26), 
      onPressed: () {
        // Hiển thị thanh thông báo trượt mượt từ cạnh phải màn hình
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, anim1, anim2) {
            return const Align(
              alignment: Alignment.centerRight,
              child: NotificationPanel(), // Gọi file thông báo độc lập ở đây
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
        
        // ĐÃ SỬA: Bọc nút cài đặt bằng Builder để tìm đúng vị trí của endDrawer
        Builder(
          builder: (innerContext) {
            return IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black87, size: 24),
              onPressed: () {
                // Sử dụng innerContext của Builder để thực thi hành động trượt mở
                Scaffold.of(innerContext).openEndDrawer();
              },
            );
          },
        ),
        
        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: VerticalDivider(color: Color(0xFFE2E8F0), width: 24)),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Nguyễn Thị Thu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
            Text('Thu ngân', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFE2E8F0),
          child: Text('NT', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24), onPressed: () {}),
        const SizedBox(width: 12),
      ],
    );
  }

  // ================= THIẾT KÊ KHỐI THỐNG KÊ CHIỀU CAO 130 =================
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Doanh thu hôm nay',
                  value: '12.450.000đ',
                  trend: '+15% so với hôm qua',
                  icon: Text('\$', style: TextStyle(fontSize: 22, color: Color(0xFF1E293B))),
                ),
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Bệnh nhân đã thanh toán',
                  value: '24',
                  trend: '+8% so với hôm qua',
                  icon: Icon(Icons.people_alt_outlined, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Hóa đơn đã xuất',
                  value: '24',
                  trend: null,
                  icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Doanh thu tháng này',
                  value: '285.600.000đ',
                  trend: '+22% so với tháng trước',
                  icon: Icon(Icons.trending_up_rounded, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= THANH CHUYỂN TAB ĐIỀU HƯỚNG LOGIC =================
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
  Widget _tabButton(String title, int index) {
    bool isActive = activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: isActive ? const Color(0xFF070412) : Colors.transparent,
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isActive ? Colors.white : Colors.black)),
        ),
      ),
    );
  }
  Widget _buildQueueView() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hàng đợi thanh toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const Text(
          '4 bệnh nhân đang chờ',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Thanh tìm kiếm bệnh nhân trong hàng đợi
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bệnh nhân đang chờ...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(color: Color(0xFFF1F5F9), height: 1),

        // Danh sách bệnh nhân (Đã sửa lỗi cú pháp nằm trong mảng children)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Color(0xFF475569)),
          ),
          title: const Text(
            'Nguyễn Văn An (BN001)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: const Text(
            'Thời gian đến: 09:30 • Tổng: 375.000đ',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          onTap: () {
            // Đã đổi sang lệnh mở thanh trượt Side Panel bên phải chuẩn UI/UX Dashboard
            Scaffold.of(context).openEndDrawer();
          },
        ),
      ],
    ),
  );
}

  Widget _buildSingleTab(String title, int index) {
    bool isActive = activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            activeTab = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF070412) : Colors.transparent,
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

  // ================= VIEW 1: HÀNG ĐỢI THANH TOÁN =================
  // Widget _buildQueueView() {
  //   return Padding(
  //     padding: const EdgeInsets.all(24.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text('Hàng đợi thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
  //         const SizedBox(height: 4),
  //         const Text('4 bệnh nhân đang chờ', style: TextStyle(color: Colors.grey, fontSize: 14)),
  //         const SizedBox(height: 20),

  //         // Thanh tìm kiếm bệnh nhân trong hàng đợi
  //         TextField(
  //           decoration: InputDecoration(
  //             hintText: 'Tìm kiếm bệnh nhân đang chờ...',
  //             hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
  //             prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
  //             contentPadding: const EdgeInsets.symmetric(vertical: 12),
  //             filled: true,
  //             fillColor: const Color(0xFFF8FAFC),
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
  //             enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         const Divider(color: Color(0xFFF1F5F9), height: 1),

  //         // Danh sách chi tiết bệnh nhân chuẩn như ảnh
  //         _buildPatientCard(
  //           name: 'Nguyễn Văn An', id: 'BN001', time: '09:30', servicesCount: 2, medsText: '2 loại thuốc', price: '375.000đ',
  //           tags: ['Khám tổng quát', 'Xét nghiệm máu'],
  //         ),
  //         _buildPatientCard(
  //           name: 'Trần Thị Bình', id: 'BN002', time: '10:15', servicesCount: 2, medsText: '1 loại thuốc', price: '628.000đ',
  //           tags: ['Siêu âm', 'X-quang'],
  //         ),
  //         _buildPatientCard(
  //           name: 'Lê Văn Cường', id: 'BN003', time: '10:45', servicesCount: 2, medsText: '2 loại thuốc', price: '606.800đ',
  //           tags: ['Khám chuyên khoa', 'Điện tâm đồ'],
  //         ),
  //         _buildPatientCard(
  //           name: 'Phạm Thị Dung', id: 'BN004', time: '11:00', servicesCount: 2, medsText: 'Không kèm thuốc', price: '350.000đ',
  //           tags: ['Khám răng', 'Cạo vôi'],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ================= VIEW 2: LỊCH SỬ GIAO DỊCH =================
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
                children: const [
                  Text('Lịch sử giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Danh sách thanh toán hôm nay', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
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

          // Ô tìm kiếm + Lọc nâng cao
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, Mã BN, số hóa đơn...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
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

          // Thiết kế tiêu đề Bảng dữ liệu lịch sử
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 2))),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('Số HĐ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 4, child: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Mã BN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 3, child: Text('Phương thức', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
              ],
            ),
          ),

          // Các dòng dữ liệu mẫu đã thanh toán thành công
          _buildHistoryRow('HD0011', 'Hoàng Văn Minh', 'BN011', '08:15', 'Chuyển khoản', '540.000đ', Icons.sync_alt_rounded),
          _buildHistoryRow('HD0012', 'Vũ Tuyết Mai', 'BN012', '08:30', 'Tiền mặt', '350.000đ', Icons.payments_outlined),
          _buildHistoryRow('HD0013', 'Đặng Đình Toàn', 'BN013', '08:45', 'Quẹt thẻ', '1.200.000đ', Icons.credit_card),
          _buildHistoryRow('HD0014', 'Bùi Bích Phương', 'BN014', '09:05', 'Chuyển khoản', '210.000đ', Icons.sync_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String hd, String name, String bn, String time, String method, String price, IconData methodIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(hd, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 4, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(bn, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 2, child: Text(time, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 3, child: Row(
            children: [
              Icon(methodIcon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(method, style: const TextStyle(fontSize: 14)),
            ],
          )),
          Expanded(flex: 2, child: Text(price, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Text('Hoàn thành', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  // ================= DESIGN HÀNG ĐỢI CHI TIẾT THEO ẢNH MẪU =================
  Widget _buildPatientCard({
    required String name, required String id, required String time,
    required int servicesCount, required String medsText, required String price,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE2E8F0),
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
    );
  }
}

// Widget Thẻ thống kê độc lập
class StatCard extends StatelessWidget {
  final String title; final String value; final String? trend; final Widget icon;
  const StatCard({super.key, required this.title, required this.value, this.trend, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(trend!, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                    ],
                  )
                ],
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: icon,
          ),
        ],
      ),
    );
  }
}