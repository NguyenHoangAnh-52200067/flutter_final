// import 'package:flutter/material.dart';

// class CustomButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;
//   final Color backgroundColor;
//   final Color textColor;
//   final double fontSize;
//   final double height;
//   final double width;
//   final bool isLoading;
//   final EdgeInsetsGeometry? padding;

//   const CustomButton({
//     super.key,
//     required this.text,
//     required this.onPressed,
//     this.backgroundColor = Colors.black,
//     this.textColor = Colors.white,
//     this.fontSize = 18,
//     this.height = 50,
//     this.width = double.infinity,
//     this.isLoading = false,
//     this.padding,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: padding ?? EdgeInsets.zero,
//       child: SizedBox(
//         width: width,
//         height: height,
//         child: ElevatedButton(
//           onPressed: isLoading ? null : onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: backgroundColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(5),
//             ),
//           ),
//           child: isLoading
//               ? const CircularProgressIndicator(color: Colors.white)
//               : Text(
//                   text,
//                   style: TextStyle(
//                     color: textColor,
//                     fontSize: fontSize,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double height;
  final double width;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.fontSize = 20,
    this.height = 50,
    this.width = double.infinity,
    this.isLoading = false,
    this.padding,
    this.icon,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: AnimatedOpacity(
        opacity: widget.isLoading ? 0.7 : _opacityAnimation.value,
        duration: const Duration(milliseconds: 500),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.textColor,
                    size: widget.fontSize - 6,
                  ), // Giảm kích thước icon
                  const SizedBox(width: 8),
                ],
                Flexible(
                  // Đảm bảo text co lại nếu cần
                  child:
                      widget.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            widget.text,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow:
                                TextOverflow.ellipsis, // Cắt text nếu quá dài
                            textAlign: TextAlign.center,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
