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
      leading: Icon(icon, size: 30, color: Colors.black),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subTitle,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
