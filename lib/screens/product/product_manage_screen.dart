import 'package:ecomerce_app/models/product_model.dart';
import 'package:ecomerce_app/repository/product_repository.dart';
import 'package:ecomerce_app/screens/product/add_product_screen.dart';
import 'package:ecomerce_app/screens/product/edit_product_screen.dart';
import 'package:ecomerce_app/screens/product/product_detail_screen.dart';
import 'package:ecomerce_app/utils/image_utils.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:flutter/material.dart';

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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_isSelecting ? "Chọn sản phẩm" : "Quản lý sản phẩm"),
        backgroundColor: const Color(0xFF7AE582),
        centerTitle: true,
        actions:
            _isSelecting
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _confirmDeleteMultipleProducts,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelecting = false;
                        _selectedProducts.clear();
                      });
                    },
                  ),
                ]
                : [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _navigateToAddProduct,
                  ),
                ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 20,
                          color: const Color(0xFF7AE582),
                          margin: const EdgeInsets.only(right: 10),
                        ),
                        const Text(
                          "Sản phẩm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            color:
                                !isGridView
                                    ? const Color(0xFF7AE582)
                                    : Colors.grey,
                          ),
                          onPressed: () => setState(() => isGridView = false),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.grid_view,
                            color:
                                isGridView
                                    ? const Color(0xFF7AE582)
                                    : Colors.grey,
                          ),
                          onPressed: () => setState(() => isGridView = true),
                        ),
                      ],
                    ),
                  ],
                ),

                // Search
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm sản phẩm...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child:
                      _filteredProducts.isEmpty
                          ? const Center(
                            child: Text("Không tìm thấy sản phẩm nào"),
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

  // Grid View
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: _allProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        final isSelected = _selectedProducts.contains(product.id);
        return GestureDetector(
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 138,
                      width: double.infinity,
                      child: ImageUtils.buildImage(
                        product.images.isNotEmpty ? product.images[0] : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (product.discount > 0) ...[
                            Center(
                              child: Text(
                                Utils.formatCurrency(
                                  product.price * (1 - product.discount / 100),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                Utils.formatCurrency(product.price),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ] else
                            Center(
                              child: Text(
                                Utils.formatCurrency(product.price),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          if (_isSelecting)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.blue,
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
                                if (isSelected && _selectedProducts.length == 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => _editProduct(product),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (product.discount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
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
      },
    );
  }

  // List View
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        final isSelected = _selectedProducts.contains(product.id);
        return GestureDetector(
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSelecting)
                        Checkbox(
                          value: isSelected,
                          activeColor: Colors.blue,
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ImageUtils.buildImage(
                          product.images.isNotEmpty ? product.images[0] : null,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Utils.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          Utils.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  trailing:
                      isSelected && _selectedProducts.length == 1
                          ? IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _editProduct(product),
                          )
                          : null,
                ),
              ),

              if (product.discount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
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
      },
    );
  }

  void _confirmDeleteMultipleProducts() {
    if (_selectedProducts.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: Text(
              "Bạn có chắc muốn xóa ${_selectedProducts.length} sản phẩm đã chọn không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, true);

                  for (String id in _selectedProducts) {
                    await _productRepo.deleteProduct(id);
                  }

                  setState(() {
                    _isSelecting = false;
                    _selectedProducts.clear();
                    _loadProducts();
                  });
                  Navigator.pop(context);
                },
                child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
