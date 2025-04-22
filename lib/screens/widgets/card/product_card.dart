import 'package:ecomerce_app/models/product_model.dart';
import 'package:ecomerce_app/screens/product/product_detail_screen.dart';
import 'package:ecomerce_app/utils/image_utils.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProductDetailScreen(product: product, fromDashboard: true),
          ),
        );
      },
      child: Stack(
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImageUtils.buildImage(
                      product.images[0],
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.discount > 0)
                        Text(
                          Utils.formatCurrency(
                            product.price * (1 - product.discount / 100),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        Utils.formatCurrency(product.price),
                        style: TextStyle(
                          fontSize: product.discount > 0 ? 12 : 14,
                          color:
                              product.discount > 0 ? Colors.grey : Colors.red,
                          fontWeight:
                              product.discount > 0
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                          decoration:
                              product.discount > 0
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Utils.buildStarRating(product.rating, size: 18),
                ],
              ),
            ),
          ),

          if (product.discount > 0)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  "-${product.discount}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
