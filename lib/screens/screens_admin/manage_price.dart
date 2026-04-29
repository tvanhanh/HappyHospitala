import 'package:flutter/material.dart';
import '../../services/api_department.dart';

class ManagePriceScreen extends StatefulWidget {
  const ManagePriceScreen({super.key});

  @override
  State<ManagePriceScreen> createState() => _ManagePriceScreenState();
}

class _ManagePriceScreenState extends State<ManagePriceScreen> {
  List<Map<String, dynamic>> departments = [];
  Map<String, TextEditingController> priceControllers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    setState(() => isLoading = true);

    try {
      final data = await DepartmentService.getDepartments();

      setState(() {
        departments = List<Map<String, dynamic>>.from(data);

        // tạo controller cho từng khoa
        for (var dept in departments) {
          final id = dept['id'];
          priceControllers[id] = TextEditingController(
            text: (dept['price'] ?? '').toString(),
          );
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi load phòng ban: $e")),
      );
    }
  }

  Future<void> updatePrice(String departmentId) async {
    final priceText = priceControllers[departmentId]?.text ?? "";

    if (priceText.isEmpty) return;

    final price = int.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giá không hợp lệ")),
      );
      return;
    }

    try {
      //await DepartmentService.updateDepartmentPrice(departmentId, price);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật giá thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý giá khám"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final dept = departments[index];
                final id = dept['id'];
                final name = dept['departmentName'] ?? "Không rõ";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: priceControllers[id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Giá khám (VNĐ)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.money),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => updatePrice(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: const Text("Cập nhật giá"),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
