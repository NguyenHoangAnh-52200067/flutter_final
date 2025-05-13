import 'package:ecommerce_app/screens/widgets/custom_shape/custom_curved.dart';
import 'package:flutter/material.dart';

class CurvedWidget extends StatelessWidget {
  final Widget? child;

  const CurvedWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(clipper: CustomCurved(), child: child);
  }
}
