import 'package:flutter/material.dart';

class SectionHeading1 extends StatelessWidget {
  final Color? textColor;
  final bool showActionButton;
  final String title, buttonTitle;
  final void Function()? onPressed;

  const SectionHeading1({
    super.key,
    this.textColor,
    this.showActionButton = true,
    required this.title,
    this.buttonTitle = 'Hello',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontSize: 18,
            color: textColor ?? Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showActionButton)
          TextButton(
            onPressed: onPressed,
            child: Text(
              buttonTitle,
              style: const TextStyle(
                color: Colors.white, // Văn bản nút màu trắng
                fontWeight: FontWeight.normal,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue, // Nền nút màu xanh
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}
