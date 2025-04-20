import 'package:flutter/material.dart';

class MedicineInventory extends StatefulWidget {
  @override
  _MedicineInventoryState createState() => _MedicineInventoryState();
}

class _MedicineInventoryState extends State<MedicineInventory> {
  List<Map<String, String>> medicineList = [
    {
      'name': 'Paracetamol',
      'quantity': '200',
      'unit': 'viên',
      'expiry': '12/2025',
    },
    {
      'name': 'Amoxicillin',
      'quantity': '150',
      'unit': 'viên',
      'expiry': '08/2024',
    },
  ];

  void _addMedicine() {
    // TODO: Hiển thị form dialog hoặc điều hướng đến màn hình thêm thuốc
  }

  void _editMedicine(int index) {
    // TODO: Hiển thị form dialog hoặc điều hướng đến màn hình sửa thuốc
  }

  void _deleteMedicine(int index) {
    setState(() {
      medicineList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý thuốc & kho'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addMedicine,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: medicineList.length,
        itemBuilder: (context, index) {
          final medicine = medicineList[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(Icons.medical_services, color: Colors.green),
              title: Text(medicine['name'] ?? ''),
              subtitle: Text(
                  'Số lượng: ${medicine['quantity']} ${medicine['unit']} | Hạn dùng: ${medicine['expiry']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editMedicine(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMedicine(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
