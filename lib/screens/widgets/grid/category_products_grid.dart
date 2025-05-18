
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/widgets/card/product_card.dart';
import 'package:animate_do/animate_do.dart'; // Thêm thư viện animate_do

class CategoryProductsGrid extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final int crossAxisCount;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const CategoryProductsGrid({
    super.key,
    required this.categoryName,
    required this.categoryId,
    this.crossAxisCount = 2,
    this.scrollController,
    this.padding,
  });

  @override
  State<CategoryProductsGrid> createState() => _CategoryProductsGridState();
}

class _CategoryProductsGridState extends State<CategoryProductsGrid> {
  final ProductRepository _productRepo = ProductRepository();
  final List<ProductModel> _products = [];
  late final ScrollController _effectiveScrollController;

  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  String categoryName = '';

  @override
  void initState() {
    super.initState();
    _effectiveScrollController = widget.scrollController ?? ScrollController();
    _effectiveScrollController.addListener(_onScroll);
    _loadProducts();
    categoryName = widget.categoryName;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _effectiveScrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_effectiveScrollController.hasClients) return;

    final maxScroll = _effectiveScrollController.position.maxScrollExtent;
    final currentScroll = _effectiveScrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final result = await _productRepo.getProductsByCategory2(
        widget.categoryId,
        lastDoc: _lastDoc,
      );

      if (!mounted) return;

      setState(() {
        if (result["products"].isNotEmpty) {
          _products.addAll(result["products"]);
          _lastDoc = result["lastDoc"];
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
                            'Danh mục các sản phẩm $categoryName',
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
                SizedBox(height: 8),
                Expanded(
                  child: FadeInUp(
                    duration: Duration(milliseconds: 600),
                    child: GridView.builder(
                      controller: _effectiveScrollController,
                      padding: widget.padding ?? const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.crossAxisCount,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 280,
                      ),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length) {
                          return _buildLoadingIndicator();
                        }
                        return FadeInUp(
                          duration: Duration(milliseconds: 700 + index * 100),
                          child: ProductCard(product: _products[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        ),
      ),
    );
  }
}