// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ecommerce_app/models/product_model.dart';
// import 'package:ecommerce_app/repository/product_repository.dart';
// import 'package:ecommerce_app/screens/widgets/card/product_card.dart';

// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';

// class ProductListView extends StatefulWidget {
//   final String categoryId;

//   const ProductListView({super.key, required this.categoryId});

//   @override
//   State<ProductListView> createState() => _ProductListViewState();
// }

// class _ProductListViewState extends State<ProductListView> {
//   final ProductRepository _productRepo = ProductRepository();
//   final List<ProductModel> _products = [];
//   bool _isLoading = false;
//   DocumentSnapshot? _lastDoc;
//   bool _hasMore = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   void _loadProducts() async {
//     if (_isLoading || !_hasMore) return;
//     setState(() => _isLoading = true);

//     var result = await _productRepo.getProductsByCategory2(
//       widget.categoryId,
//       lastDoc: _lastDoc,
//     );

//     List<ProductModel> newProducts = result["products"];
//     DocumentSnapshot? newLastDoc = result["lastDoc"];

//     if (newProducts.isEmpty) {
//       setState(() {
//         _hasMore = false;
//         _isLoading = false;
//       });
//       return;
//     }

//     setState(() {
//       _products.addAll(newProducts);
//       _lastDoc = newLastDoc;
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 240,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         itemCount:
//             _products.isNotEmpty ? _products.length + (_hasMore ? 1 : 0) : 6,
//         itemBuilder: (context, index) {
//           if (_products.isEmpty) {
//             return _buildShimmerCard();
//           }

//           if (index == _products.length) {
//             return _hasMore ? _buildShimmerCard() : const SizedBox.shrink();
//           }

//           ProductModel product = _products[index];
//           return Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: ProductCard(product: product),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildShimmerCard() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         width: 160,
//         margin: const EdgeInsets.only(right: 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 140,
//               width: 135,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             const SizedBox(height: 15),
//             Container(
//               height: 16,
//               width: 135,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Container(
//               height: 16,
//               width: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Container(
//               height: 16,
//               width: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Container(
//               height: 16,
//               width: 120,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/widgets/card/product_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductListView extends StatefulWidget {
  final String categoryId;

  const ProductListView({super.key, required this.categoryId});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView>
    with SingleTickerProviderStateMixin {
  final ProductRepository _productRepo = ProductRepository();
  final List<ProductModel> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  // Animation controller for product card appearance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Start animation when products load
    _animationController.forward();
  }

  void _loadProducts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    var result = await _productRepo.getProductsByCategory2(
      widget.categoryId,
      lastDoc: _lastDoc,
    );

    List<ProductModel> newProducts = result["products"];
    DocumentSnapshot? newLastDoc = result["lastDoc"];

    if (newProducts.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _products.addAll(newProducts);
      _lastDoc = newLastDoc;
      _isLoading = false;
      _animationController.reset();
      _animationController.forward(); // Trigger animation for new products
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount:
            _products.isNotEmpty ? _products.length + (_hasMore ? 1 : 0) : 6,
        itemBuilder: (context, index) {
          if (_products.isEmpty) {
            return _buildShimmerCard();
          }

          if (index == _products.length) {
            return _hasMore ? _buildShimmerCard() : const SizedBox.shrink();
          }

          ProductModel product = _products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ProductCard(product: product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.blue.shade100, // Màu xanh nhạt
      highlightColor: Colors.blue.shade50, // Màu xanh rất nhạt
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: 135,
              decoration: BoxDecoration(
                color: Colors.white, // Nền trắng
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.shade300,
                ), // Viền xanh nhạt
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 16,
              width: 135,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
