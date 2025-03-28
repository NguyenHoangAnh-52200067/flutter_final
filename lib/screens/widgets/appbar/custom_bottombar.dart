import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;


  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
          offset: Offset(0, 5),
        ),
      ],
    ),
      child: GNav(
        gap: 8,
        backgroundColor: Colors.white,
        color: Colors.grey[600],
        activeColor: Colors.black,
        tabBackgroundColor: const Color(0xFF7AE582).withOpacity(0.2),
        padding: const EdgeInsets.all(10),
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
        tabs: const [
          GButton(
            icon: Icons.home,
            text: "Trang chủ",
          ),
          GButton(
            icon: Icons.person,
            text: "Tài khoản",
          ),
        ],
      ),
    );
  }
}