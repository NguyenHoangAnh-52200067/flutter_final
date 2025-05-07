import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  // Format tiền VNĐ
  static String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(price);
  }

  // Hiển thị đánh giá sao 
  static Widget buildStarRating(double rating, {double size = 20}) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}