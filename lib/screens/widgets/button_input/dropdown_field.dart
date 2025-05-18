import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final IconData? icon;
  final TextStyle? hintStyle;
  final Color? iconColor;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final Color? dropdownColor;
  final TextStyle? style;

  DropdownField({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.hintStyle,
    this.iconColor,
    this.border,
    this.focusedBorder,
    this.dropdownColor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          enabledBorder:
              border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade300,
                ), // Viền xanh nhạt
              ),
          focusedBorder:
              focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue,
                  width: 2,
                ), // Viền xanh đậm khi focus
              ),
          fillColor: Colors.white,
          filled: true,
          prefixIcon:
              icon != null ? Icon(icon, color: iconColor ?? Colors.blue) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        isExpanded: true,
        hint: Text(
          hintText,
          style: hintStyle ?? TextStyle(color: Colors.blue.shade300),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.blue,
        ), // Biểu tượng dropdown xanh dương
        onChanged: onChanged,
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: style ?? TextStyle(color: Colors.blue.shade700),
                ),
              );
            }).toList(),
        dropdownColor: dropdownColor ?? Colors.white, // Dropdown nền trắng
      ),
    );
  }
}
