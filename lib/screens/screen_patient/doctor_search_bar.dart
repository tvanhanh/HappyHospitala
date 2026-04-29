import 'package:flutter/material.dart';

class DoctorSearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const DoctorSearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: (value) {
        onSearch(value);
      },
      decoration: InputDecoration(
        hintText: "Tìm bác sĩ, chuyên khoa...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
