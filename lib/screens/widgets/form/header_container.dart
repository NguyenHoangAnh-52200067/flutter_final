import 'package:ecomerce_app/screens/widgets/custom_shape/custom_circular.dart';
import 'package:ecomerce_app/screens/widgets/form/curved_widget.dart';
import 'package:flutter/material.dart';

class HeaderContainer extends StatelessWidget {
  final Widget child;

  const HeaderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CurvedWidget(
      child: Container(
        color: const Color(0xFF7AE582),
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -250,
              child: CustomCircular(
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              top: 100,
              right: -300,
              child: CustomCircular(
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
