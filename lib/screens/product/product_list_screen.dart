import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/product/edit_product_screen.dart';
import 'package:ecommerce_app/screens/product/product_detail_screen.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:animate_do/animate_do.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProductListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductRepository _productRepo = ProductRepository();
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProductsByCategory(
      widget.categoryId,
    );
    setState(() {
      _products = products;
    });
  }

  void _editProduct(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );

    if (result == true) {
      // Reload products if update was successful
      _loadProducts();
    }
  }

  void _deleteProduct(ProductModel product) async {
    await _productRepo.deleteProduct(product.id!);
    setState(() {
      _products.remove(product);
    });
    _showSuccessSnackBar("Sản phẩm đã được xóa");
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFBBDEFB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              children: [
                FadeInDown(
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF2196F3).withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ZoomIn(
                          duration: Duration(milliseconds: 300),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Sản phẩm - ${widget.categoryName}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child:
                      _products.isEmpty
                          ? FadeInUp(
                            duration: Duration(milliseconds: 600),
                            child: Center(
                              child: Text(
                                "Không có sản phẩm nào",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return FadeInUp(
                                duration: Duration(
                                  milliseconds: 700 + index * 100,
                                ),
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color: Color(0xFFBBDEFB),
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 5,
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: Slidable(
                                    key: Key(product.id ?? ""),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.3,
                                      children: [
                                        SlidableAction(
                                          onPressed:
                                              (context) =>
                                                  _editProduct(product),
                                          backgroundColor: Color(0xFF2196F3),
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Sửa',
                                        ),
                                        SlidableAction(
                                          onPressed:
                                              (context) =>
                                                  _deleteProduct(product),
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Xóa',
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          child: _buildImage(
                                            product.images.isNotEmpty
                                                ? product.images[0]
                                                : null,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        product.productName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1976D2),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        Utils.formatCurrency(product.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
                                      ),
                                      trailing: ZoomIn(
                                        duration: Duration(milliseconds: 400),
                                        child: Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF2196F3),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ProductDetailScreen(
                                                      product: product,
                                                    ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      );
    }
    return ZoomIn(
      duration: Duration(milliseconds: 500),
      child: Image.network(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50, color: Colors.red);
        },
      ),
    );
  }
}
