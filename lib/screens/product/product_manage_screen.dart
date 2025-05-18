import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/product/add_product_screen.dart';
import 'package:ecommerce_app/screens/product/edit_product_screen.dart';
import 'package:ecommerce_app/screens/product/product_detail_screen.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // Thêm thư viện animate_do

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedProducts = {};
  bool isGridView = false;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getAllProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductScreen()),
    );
    _loadProducts();
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts =
          _allProducts
              .where(
                (product) => product.productName.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
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
      // Reload all products if update was successful
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: FadeInDown(
          duration: Duration(milliseconds: 500),
          child: Text(
            _isSelecting ? "Chọn sản phẩm" : "Quản lý sản phẩm",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color(0xFF2196F3), // Màu xanh dương
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions:
            _isSelecting
                ? [
                  ZoomIn(
                    duration: Duration(milliseconds: 300),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      onPressed: _confirmDeleteMultipleProducts,
                    ),
                  ),
                  ZoomIn(
                    duration: Duration(milliseconds: 400),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isSelecting = false;
                          _selectedProducts.clear();
                        });
                      },
                    ),
                  ),
                ]
                : [
                  ZoomIn(
                    duration: Duration(milliseconds: 300),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: _navigateToAddProduct,
                    ),
                  ),
                ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                FadeInUp(
                  duration: Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            margin: const EdgeInsets.only(right: 12),
                          ),
                          Text(
                            "Sản phẩm",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ZoomIn(
                            duration: Duration(milliseconds: 300),
                            child: IconButton(
                              icon: Icon(
                                Icons.list,
                                color:
                                    !isGridView
                                        ? Color(0xFF2196F3)
                                        : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => isGridView = false),
                            ),
                          ),
                          ZoomIn(
                            duration: Duration(milliseconds: 400),
                            child: IconButton(
                              icon: Icon(
                                Icons.grid_view,
                                color:
                                    isGridView
                                        ? Color(0xFF2196F3)
                                        : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => isGridView = true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 700),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFBBDEFB), width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterProducts,
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm sản phẩm...",
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF2196F3),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      _filteredProducts.isEmpty
                          ? FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: Center(
                              child: Text(
                                "Không tìm thấy sản phẩm nào",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                          : isGridView
                          ? _buildGridView()
                          : _buildListView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isSelected = _selectedProducts.contains(product.id);
        return FadeInUp(
          duration: Duration(milliseconds: 600 + index * 100),
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _selectedProducts.add(product.id!);
              });
            },
            onTap: () {
              if (_isSelecting) {
                setState(() {
                  if (isSelected) {
                    _selectedProducts.remove(product.id!);
                  } else {
                    _selectedProducts.add(product.id!);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              }
            },
            child: Card(
              color: isSelected ? Color(0xFFBBDEFB) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ImageUtils.buildImage(
                              product.images.isNotEmpty
                                  ? product.images[0]
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        if (product.discount > 0) ...[
                          Text(
                            Utils.formatCurrency(
                              product.price * (1 - product.discount / 100),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Utils.formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else
                          Text(
                            Utils.formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (_isSelecting)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElasticIn(
                                duration: Duration(milliseconds: 300),
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Color(0xFF2196F3),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedProducts.add(product.id!);
                                      } else {
                                        _selectedProducts.remove(product.id!);
                                      }
                                    });
                                  },
                                ),
                              ),
                              if (isSelected && _selectedProducts.length == 1)
                                ZoomIn(
                                  duration: Duration(milliseconds: 300),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Color(0xFF2196F3),
                                    ),
                                    onPressed: () => _editProduct(product),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (product.discount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: ElasticIn(
                        duration: Duration(milliseconds: 400),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "-${product.discount}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isSelected = _selectedProducts.contains(product.id);
        return FadeInUp(
          duration: Duration(milliseconds: 600 + index * 100),
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _selectedProducts.add(product.id!);
              });
            },
            onTap: () {
              if (_isSelecting) {
                setState(() {
                  if (isSelected) {
                    _selectedProducts.remove(product.id!);
                  } else {
                    _selectedProducts.add(product.id!);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              }
            },
            child: Card(
              color: isSelected ? Color(0xFFBBDEFB) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              margin: const EdgeInsets.only(bottom: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSelecting)
                          ElasticIn(
                            duration: Duration(milliseconds: 300),
                            child: Checkbox(
                              value: isSelected,
                              activeColor: Color(0xFF2196F3),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedProducts.add(product.id!);
                                  } else {
                                    _selectedProducts.remove(product.id!);
                                  }
                                });
                              },
                            ),
                          ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            child: ImageUtils.buildImage(
                              product.images.isNotEmpty
                                  ? product.images[0]
                                  : null,
                            ),
                          ),
                        ),
                      ],
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
                    subtitle: Wrap(
                      children: [
                        if (product.discount > 0) ...[
                          Text(
                            Utils.formatCurrency(
                              product.price * (1 - product.discount / 100),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            Utils.formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else
                          Text(
                            Utils.formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing:
                        isSelected && _selectedProducts.length == 1
                            ? ZoomIn(
                              duration: Duration(milliseconds: 300),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Color(0xFF2196F3),
                                ),
                                onPressed: () => _editProduct(product),
                              ),
                            )
                            : null,
                  ),
                  if (product.discount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: ElasticIn(
                        duration: Duration(milliseconds: 400),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "-${product.discount}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteMultipleProducts() {
    if (_selectedProducts.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              "Xác nhận xóa",
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Bạn có chắc muốn xóa ${_selectedProducts.length} sản phẩm đã chọn không?",
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Hủy", style: TextStyle(color: Color(0xFF2196F3))),
              ),
              _buildAnimatedButton(
                text: "Xóa",
                icon: Icons.delete,
                onPressed: () async {
                  Navigator.pop(context);
                  for (String id in _selectedProducts) {
                    await _productRepo.deleteProduct(id);
                  }
                  setState(() {
                    _isSelecting = false;
                    _selectedProducts.clear();
                    _loadProducts();
                  });
                },
                isDanger: true,
              ),
            ],
          ),
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDanger
                    ? [Colors.red, Colors.redAccent]
                    : [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDanger ? Colors.red : Color(0xFF2196F3)).withOpacity(
                0.4,
              ),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElasticIn(
              duration: Duration(milliseconds: 300),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
