import 'package:flutter/material.dart';
import 'dispense_medicine_dialog.dart'; // Import để dùng chung hệ màu hằng số
import '../../services/api_inventory.dart';

class Step1Page extends StatefulWidget {
  final Map<String, dynamic> prescription;
  final List<dynamic> medicines; // Chuyển sang định kiểu rõ ràng hơn cho List
  final String dateDisplay;
  final Function(List<dynamic>) onMedicinesUpdated; // 🟢 THÊM: Callback để truyền dữ liệu đã cập nhật số lượng ra ngoài nếu cần

  const Step1Page({
    super.key,
    required this.prescription,
    required this.medicines,
    required this.dateDisplay,
    required this.onMedicinesUpdated, // Nhận callback từ widget cha (DispenseMedicineDialog)
  });

  @override
  State<Step1Page> createState() => _Step1PageState();
}

class _Step1PageState extends State<Step1Page> {
  List<dynamic> _updatedMedicines = [];
  bool _isLoadingStock = true;

  @override
  void initState() {
    super.initState();
    _fetchRealtimeStock();
  }

  // Khởi chạy lại nếu danh sách thuốc từ widget cha thay đổi ngoài ý muốn
  @override
  void didUpdateWidget(covariant Step1Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.medicines != oldWidget.medicines) {
      _fetchRealtimeStock();
    }
  }

  void _fetchRealtimeStock() async {
    try {
      // 1. Gom tất cả ID thuốc được kê đơn
      List<String> medicineIds = widget.medicines
          .map((med) => med['id']?.toString() ?? '') 
          .where((id) => id.isNotEmpty)
          .toList();

      if (medicineIds.isEmpty) {
        if (mounted) {
          setState(() {
            _updatedMedicines = List.from(widget.medicines);
            _isLoadingStock = false;
          });
        }
        return;
      }

      // 2. Gọi API lấy dữ liệu tồn kho tổng hợp thực tế từ kho
      List<dynamic> liveStockList = await ApiInventory.getMedicinesStock(medicineIds);

      // 3. Map (gộp) số lượng tồn kho thực tế vào danh sách thuốc ban đầu
      List<dynamic> tempMappedList = widget.medicines.map((med) {
        final String currentMedId = med['id']?.toString() ?? '';

        // TÌM KIẾM CHÍNH XÁC: Ép kiểu .toString() cả 2 vế để tránh lệch kiểu dữ liệu hệ thống
        final stockInfo = liveStockList.firstWhere(
          (element) => element['_id']?.toString() == currentMedId,
          orElse: () => null,
        );

        // Lấy đúng số lượng, số lô và hạn sử dụng từ bản ghi kho thuốc phù hợp nhất
        int actualStock = stockInfo != null ? (stockInfo['totalStock'] as num).toInt() : 0;
        String actualBatch = stockInfo != null ? stockInfo['batchNumber']?.toString() ?? 'N/A' : 'N/A';
        String actualExp = 'N/A';

        if (stockInfo != null && stockInfo['nearestExpiryDate'] != null) {
          actualExp = stockInfo['nearestExpiryDate'].toString().substring(0, 10);
        }

        return {
          ...med,
          'stock': actualStock,
          'batch': actualBatch,
          'exp': actualExp,
          'quantity': med['quantity']?.toString() ?? '0', // Bảo toàn số lượng bác sĩ kê ban đầu dưới dạng String
        };
      }).toList();

      if (mounted) {
        setState(() {
          _updatedMedicines = tempMappedList;
          _isLoadingStock = false;
        });
        // Báo ngược lại cho dialog tổng hợp nắm giữ mảng dữ liệu mới
        widget.onMedicinesUpdated(_updatedMedicines);
      }
    } catch (e) {
      print("💥 Lỗi xử lý dữ liệu kho tại Step1Page: $e");
      if (mounted) {
        setState(() {
          _updatedMedicines = List.from(widget.medicines);
          _isLoadingStock = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStock) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: kPrimaryBlue),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner thông tin
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kPrimaryBlue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Kiểm tra thông tin đơn thuốc',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1))),
                    SizedBox(height: 2),
                    Text('Xác nhận thông tin bệnh nhân và danh sách thuốc thực tế trong kho',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Khối thông tin bệnh nhân
        const Text('Thông tin bệnh nhân',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetaRow('Họ tên:', widget.prescription['patientName'] ?? 'N/A', isBoldValue: true),
              const SizedBox(height: 10),
              _buildMetaRow('Bác sĩ:', widget.prescription['doctorName'] ?? 'N/A'),
              const SizedBox(height: 10),
              _buildMetaRow('Ngày kê đơn:', widget.dateDisplay),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Khối Danh sách thuốc
        Text('Danh sách thuốc (${_updatedMedicines.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
        const SizedBox(height: 12),
        ..._updatedMedicines.map((med) {
          int requiredQty = int.tryParse(med['quantity']?.toString() ?? '0') ?? 0;
          int currentStock = med['stock'] ?? 0;
          
          // Kiểm tra xem có bị hết hàng hoặc không đủ hàng cấp phát hay không
          bool isOutOfStock = currentStock == 0 || currentStock < requiredQty;
          Color currentItemColor = isOutOfStock ? kDangerRed : kBorderColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isOutOfStock ? kDangerRed.withOpacity(0.8) : kBorderColor,
                  width: isOutOfStock ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'] ?? 'Tên thuốc',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
                const SizedBox(height: 4),
                Text(med['usage'] ?? 'Chưa có hướng dẫn sử dụng',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 40,
                      child: TextFormField(
                        initialValue: med['quantity']?.toString() ?? '0',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        onChanged: (value) {
                          // 🟢 CẢI TIẾN QUAN TRỌNG: Cập nhật lại số lượng thay đổi vào State để check Đủ/Thiếu kho tức thì
                          setState(() {
                            med['quantity'] = value;
                          });
                          widget.onMedicinesUpdated(_updatedMedicines);
                        },
                        decoration: InputDecoration(
                          labelText: 'Số lượng cấp', 
                          labelStyle: TextStyle(
                              color: isOutOfStock ? kDangerRed : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: currentItemColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: currentItemColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: isOutOfStock ? kDangerRed : kPrimaryBlue)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: isOutOfStock ? kDangerRed : kSuccessGreen,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Kho: $currentStock viên',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                          'Lô: ${med['batch']}  •  HSD: ${med['exp']}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    )
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      children: [
        Text('$label ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: kTextDark, fontSize: 14, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}