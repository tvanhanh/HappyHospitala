import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';

class PromotionManagerScreen extends ConsumerStatefulWidget {
  const PromotionManagerScreen({super.key});

  @override
  ConsumerState<PromotionManagerScreen> createState() => _PromotionManagerScreenState();
}

class _PromotionManagerScreenState extends ConsumerState<PromotionManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(promotionProvider).fetchPromotions();
    });
  }

  void _showAddPromotionDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final discountValueCtrl = TextEditingController();
    final maxDiscountCtrl = TextEditingController();
    String type = 'percent';
    String applicableFor = 'all';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            title: const Text('Thêm Khuyến Mãi Mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã Khuyến Mãi (Code)')),
                  const SizedBox(height: 10),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên Khuyến Mãi')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                    items: const [
                      DropdownMenuItem(value: 'percent', child: Text('Phần trăm (%)')),
                      DropdownMenuItem(value: 'fixed', child: Text('Cố định (VND)')),
                    ],
                    onChanged: (v) => setStateBuilder(() => type = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: discountValueCtrl,
                    decoration: const InputDecoration(labelText: 'Mức giảm (vd: 50% hoặc 100000)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: maxDiscountCtrl,
                    decoration: const InputDecoration(labelText: 'Giảm tối đa (VND) - Để trống nếu fixed'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: applicableFor,
                    decoration: const InputDecoration(labelText: 'Áp dụng cho'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'new_patient', child: Text('Bệnh nhân mới')),
                      DropdownMenuItem(value: 'insurance', child: Text('Bảo hiểm y tế (BHYT)')),
                    ],
                    onChanged: (v) => setStateBuilder(() => applicableFor = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref.read(promotionProvider).createPromotion({
                    'code': codeCtrl.text,
                    'name': nameCtrl.text,
                    'discountType': type,
                    'discountValue': double.tryParse(discountValueCtrl.text) ?? 0,
                    'maxDiscount': maxDiscountCtrl.text.isNotEmpty ? double.tryParse(maxDiscountCtrl.text) : null,
                    'applicableFor': applicableFor,
                    'validFrom': DateTime.now().toIso8601String(),
                    'validTo': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                  });
                  if (success) {
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thành công!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thất bại! Kiểm tra lại mã.')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(promotionProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPromotionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Khuyến Mãi'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage.isNotEmpty
              ? Center(child: Text(provider.errorMessage, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.promotions.length,
                  itemBuilder: (context, index) {
                    final p = provider.promotions[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.discount, color: Colors.blue),
                        ),
                        title: Text('${p['name']} (${p['code']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Loại: ${p['discountType']} - Giảm: ${p['discountValue']} \nÁp dụng: ${p['applicableFor']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await provider.deletePromotion(p['_id']);
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
