import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AppBar(
        backgroundColor: Colors.blue, // Set background to blue
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white, // White icon for contrast
                ),
              )
            : leadingIcon != null
                ? IconButton(
                    onPressed: leadingOnPressed,
                    icon: Icon(
                      leadingIcon,
                      color: Colors.white, // White icon for contrast
                    ),
                  )
                : null,
        title: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white, // White text for title
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          child: title ?? const SizedBox.shrink(),
        ),
        actions: actions?.map((action) {
          // Ensure actions (icons/buttons) use white color
          return Theme(
            data: Theme.of(context).copyWith(
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            child: action,
          );
        }).toList(),
        elevation: 2, // Subtle shadow for depth
        shadowColor: Colors.blue.shade900, // Shadow matches blue theme
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}