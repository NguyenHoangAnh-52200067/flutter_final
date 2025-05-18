import 'package:flutter/material.dart';

class VerticalImageText extends StatelessWidget {
  final Widget image;
  final String title;
  final Color textColor;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final void Function()? onTap;

  const VerticalImageText({
    super.key,
    required this.image,
    required this.title,
    this.textColor = Colors.blue,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white, // Nền trắng mặc định
            border:
                border ??
                Border.all(
                  color: Colors.blue.shade300,
                ), // Viền xanh nhạt mặc định
            borderRadius:
                borderRadius ??
                BorderRadius.circular(12), // Góc bo tròn mặc định
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, // Nền trắng cho hình ảnh
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(child: image),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 50,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontSize: 12,
                    color: textColor, // Sử dụng textColor cho văn bản
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
