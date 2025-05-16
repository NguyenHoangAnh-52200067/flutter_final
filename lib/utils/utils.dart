import 'package:ecommerce_app/models/comment_model.dart';
import 'package:ecommerce_app/repository/comment_repository.dart';
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

  static double calculateAverageRating(List<CommentModel> comments) {
    if (comments.isEmpty) return 0.0;

    double totalRating = 0.0;
    int ratedCommentsCount = 0;

    for (var comment in comments) {
      if (comment.rating != null) {
        totalRating += comment.rating!;
        ratedCommentsCount++;
      }
    }

    return ratedCommentsCount > 0 ? totalRating / ratedCommentsCount : 0.0;
  }

  static Future<Widget> getProductRatingStars(
    String productId, {
    double size = 20,
  }) async {
    final CommentRepository _commentRepo = CommentRepository();
    final comments = await _commentRepo.getProductComments(productId);
    double rating = calculateAverageRating(comments);

    final roundedRating = (rating * 2).round() / 2;

    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            if (index < roundedRating.floor()) {
              // Full star
              return Icon(Icons.star, color: Colors.amber, size: size);
            } else if (index == roundedRating.floor() &&
                roundedRating % 1 != 0) {
              // Half star
              return Icon(Icons.star_half, color: Colors.amber, size: size);
            } else {
              // Empty star
              return Icon(Icons.star_border, color: Colors.amber, size: size);
            }
          }),
        ),
        SizedBox(width: 5),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : "Chưa có đánh giá",
          style: TextStyle(color: Colors.grey[600], fontSize: size * 0.8),
        ),
      ],
    );
  }
}
