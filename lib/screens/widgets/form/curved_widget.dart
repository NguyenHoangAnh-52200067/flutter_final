import 'package:flutter/material.dart';
import 'package:ecomerce_app/screens/widgets/custom_shape/custom_curved.dart';

class CurvedWidget extends StatelessWidget {
  final Widget? child;
  
  const CurvedWidget({
    super.key, this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CustomCurved(),
      child: child,
    );
  }
}