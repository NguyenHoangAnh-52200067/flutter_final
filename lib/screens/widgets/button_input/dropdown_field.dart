import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final IconData? icon;

  DropdownField({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
          fillColor: Colors.white,
          filled: true,
          prefixIcon: icon != null ? Icon(icon) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        isExpanded: true,
        hint: Text(hintText, style: TextStyle(color: Colors.grey)),
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}
