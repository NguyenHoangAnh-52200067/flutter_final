import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/models/product_model.dart';
import 'package:ecomerce_app/repository/product_repository.dart';
import 'package:ecomerce_app/screens/widgets/card/product_card.dart';

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
      appBar: AppBar(
        title: Text('Danh mục các sản phẩm $categoryName'),
        backgroundColor: const Color(0xFF7AE582),
      ),
      body: GridView.builder(
        controller: _effectiveScrollController, // Use the effective controller
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
          return ProductCard(product: _products[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
