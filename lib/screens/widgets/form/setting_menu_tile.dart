// import 'package:flutter/material.dart';

// class SettingMenuTile extends StatelessWidget {
//   final IconData icon;
//   final String title, subTitle;
//   final Widget? trailing;
//   final VoidCallback? onTap;

//   const SettingMenuTile({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.subTitle,
//     this.trailing,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Icon(icon, size: 30, color: Colors.black),
//       title: Text(
//         title,
//         style: Theme.of(context).textTheme.headlineMedium!.copyWith(
//           fontSize: 14,
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       subtitle: Text(
//         subTitle,
//         style: Theme.of(context).textTheme.headlineMedium!.copyWith(
//           fontSize: 10,
//           color: Colors.black,
//           fontWeight: FontWeight.normal,
//         ),
//       ),
//       trailing: trailing,
//       onTap: onTap,
//     );
//   }
// }
import 'package:flutter/material.dart';

class SettingMenuTile extends StatelessWidget {
  final IconData icon;
  final String title, subTitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 30, color: Colors.blue), // Biểu tượng màu xanh
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 14,
          color: Colors.blue, // Tiêu đề màu xanh
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subTitle,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 10,
          color: Colors.blue.shade700, // Phụ đề màu xanh đậm hơn
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}