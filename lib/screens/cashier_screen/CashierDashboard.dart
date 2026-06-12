import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Đảm bảo import thư viện định dạng tiền tệ
import 'payment_form.dart';
import 'settings_panel.dart';
import 'notification_panel.dart';
import '../../models/prescription_model.dart';
import '../../services/api_prescription.dart';
import '../../models/bill_model.dart';
import '../../services/api_bill.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  int activeTab = 0; // 0: Hàng đợi thanh toán, 1: Lịch sử giao dịch
  
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;
  List<BillModel> _bills = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  // 🟢 ĐỒNG BỘ ĐIỀU HƯỚNG TẢI DỮ LIỆU ĐỘNG THEO TAB ACTIVE
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (activeTab == 0) {
        final result = await ApiPrescription.getCompletedPrescriptions();
        setState(() {
          _prescriptions = result;
        });
      } else {
        // Tải dữ liệu từ ApiBill khi chuyển sang Tab Lịch sử
        final result = await ApiBill.getAllBills(page: 1, limit: 50, search: _searchQuery);
        setState(() {
          _bills = result;
        });
      }
    } catch (e) {
      print("💥 Lỗi khi cập nhật UI CashierScreen: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🟢 HÀM MỞ HỘP THOẠI THANH TOÁN (Tự động làm mới danh sách sau khi đóng dialog)
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

  String _formatMoney(int amount) {
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

  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
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
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 130,
                child: StatCard(
                  title: 'Bệnh nhân đã thanh toán',
                  value: '24',
                  trend: '+8% so với hôm qua',
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
                  value: '24',
                  trend: null,
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
                  value: '285.600.000đ',
                  trend: '+22% so với tháng trước',
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
          setState(() {
            activeTab = index;
          });
          _fetchData(); 
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
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bệnh nhân đang chờ...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
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
            String price = _formatMoney(prescription.totalPrice ?? 0);
            int servicesCount = 0;
            int medicinesCount = prescription.medicines?.length ?? 0;
            String medsText = medicinesCount > 0 ? "$medicinesCount loại thuốc" : "Không kèm thuốc";
            List<String> tags = [prescription.diagnosis.isNotEmpty ? prescription.diagnosis : "Khám bệnh"];

            return _buildPatientCard(
              name: name,
              id: id,
              time: "Vừa xong", 
              servicesCount: servicesCount,
              medsText: medsText,
              price: price,
              tags: tags,
              onTap: () => _openPaymentDialog(prescription),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 🟢 VIEW LỊCH SỬ GIAO DỊCH ĐÃ ĐƯỢC BUILD HOÀN CHỈNH TỪ DANH SÁCH HÓA ĐƠN ĐỘNG (_bills)
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

          // Ô TÌM KIẾM ĐỒNG BỘ REAL-TIME CHO TAB LỊCH SỬ HÓA ĐƠN
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _fetchData(); // Gọi lại API để truy vấn theo ký tự nhập vào
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
              ],
            ),
          ),

          if (_bills.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Không tìm thấy dữ liệu hóa đơn nào phù hợp.", style: TextStyle(color: Colors.grey))),
            ),

          // MAPPING LẶP QUA DANH SÁCH BẢN GHI ĐƯỢC TRẢ VỀ TỪ MONGODB
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
              invoiceId, 
              bill.patientName,
              bill.patientId,
              bill.timeArrived, 
              paymentMethod, 
              _formatMoney(bill.finalTotalPrice),
              paymentMethod == "Tiền mặt" ? Icons.payments_outlined : Icons.sync_alt_rounded
            );
          }).toList(),
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
              Text('Đã chi', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          )),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    trend!,
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
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