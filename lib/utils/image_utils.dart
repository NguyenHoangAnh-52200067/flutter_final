import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  // Hình ảnh
  static Widget buildImage(
    String? imagePath, {
    double width = 55,
    double height = 60,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return Icon(Icons.folder, size: width, color: Colors.grey);
    }

    if (kIsWeb) {
      return Icon(Icons.image_not_supported, size: width, color: Colors.grey);
    }

    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}
