import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/category_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/product/product_detail_screen.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';

enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc }

class SearchProductScreen extends StatefulWidget {
  const SearchProductScreen({super.key});

  @override
  State<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen>
    with SingleTickerProviderStateMixin {
  final ProductRepository _productRepo = ProductRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<ProductModel> _searchResults = [];
  List<ProductModel> _filteredResults = [];
  List<String> _categories = [];
  List<String> _brands = [];
  bool _isLoading = false;

  // Filter states
  String? _selectedCategory;
  String? _selectedBrand;
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  double _selectedRating = 0;

  // Sort state
  SortOption? _currentSort;

  // Animation controller for search bar
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Trigger animation when search input changes
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryRepo.getAllCategories();
    setState(() {
      _categories = categories.map((c) => c.name).toList();
    });
  }

  void _updateBrands(List<ProductModel> products) {
    setState(() {
      _brands =
          products
              .map((p) => p.brand)
              .where((brand) => brand.isNotEmpty)
              .toSet()
              .toList();
    });
  }

  void _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final products = await _productRepo.getAllProducts();
      final filteredProducts =
          products.where((product) {
            final name = product.productName.toLowerCase();
            final description = product.description.toLowerCase();
            final brand = product.brand.toLowerCase();
            final searchQuery = query.toLowerCase();

            return name.contains(searchQuery) ||
                description.contains(searchQuery) ||
                brand.contains(searchQuery);
          }).toList();

      setState(() {
        _searchResults = filteredProducts;
        _filteredResults = filteredProducts;
      });
      _updateBrands(filteredProducts);
    } catch (e) {
      print('Error searching products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lọc sản phẩm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Tiêu đề màu xanh
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black87,
                        ), // Biểu tượng màu xanh
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.blue.shade100,
                  ), // Đường phân cách màu xanh nhạt
                  Expanded(
                    child: ListView(
                      children: [
                        // Thương hiệu
                        const Text(
                          'Thương hiệu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Tiêu đề màu xanh
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedBrand,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue,
                              ), // Viền xanh
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black26,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          hint: const Text(
                            'Chọn thương hiệu',
                            style: TextStyle(color: Colors.black54),
                          ),
                          items:
                              _brands.map((brand) {
                                return DropdownMenuItem(
                                  value: brand,
                                  child: Text(
                                    brand,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedBrand = value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Khoảng giá
                        const Text(
                          'Khoảng giá',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Tiêu đề màu xanh
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                      width: 2,
                                    ),
                                  ),
                                  hintText: 'Giá từ',
                                  hintStyle: TextStyle(color: Colors.black54),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  hintText: 'Đến',
                                  hintStyle: TextStyle(color: Colors.black),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Danh mục
                        const Text(
                          'Danh mục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          hint: const Text(
                            'Chọn danh mục',
                            style: TextStyle(color: Colors.black),
                          ),
                          items:
                              _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Đánh giá
                        const Text(
                          'Đánh giá',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Tiêu đề màu xanh
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _selectedRating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _selectedRating.toString(),
                          activeColor: Colors.blue, // Thanh trượt màu xanh
                          inactiveColor: Colors.blue.shade100,
                          onChanged: (value) {
                            setState(() => _selectedRating = value);
                          },
                        ),
                        Text(
                          'Từ ${_selectedRating.toInt()} sao trở lên',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.blue.shade100),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBrand = null;
                              _selectedCategory = null;
                              _selectedRating = 0;
                              _minPriceController.clear();
                              _maxPriceController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Nền trắng
                            foregroundColor:
                                Colors.blue, // Văn bản và viền xanh
                            side: BorderSide(color: Colors.blue), // Viền xanh
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Đặt lại',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Nền xanh
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                            ), // Văn bản trắng
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      bool noFiltersApplied =
          _selectedBrand == null &&
          _minPriceController.text.isEmpty &&
          _maxPriceController.text.isEmpty &&
          _selectedCategory == null &&
          _selectedRating == 0;

      if (noFiltersApplied) {
        _filteredResults = _searchResults;
        return;
      }

      _filteredResults =
          _searchResults.where((product) {
            if (_selectedBrand != null &&
                product.brand.toLowerCase() != _selectedBrand!.toLowerCase()) {
              return false;
            }

            if (_minPriceController.text.isNotEmpty ||
                _maxPriceController.text.isNotEmpty) {
              final minPrice = double.tryParse(_minPriceController.text) ?? 0;
              final maxPrice =
                  double.tryParse(_maxPriceController.text) ?? double.infinity;
              if (product.price < minPrice || product.price > maxPrice) {
                return false;
              }
            }

            if (_selectedCategory != null &&
                product.categoryId.toLowerCase() !=
                    _selectedCategory!.toLowerCase()) {
              return false;
            }

            if (_selectedRating > 0 && product.rating < _selectedRating) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  void _sortProducts() {
    setState(() {
      switch (_currentSort) {
        case SortOption.nameAsc:
          _filteredResults.sort(
            (a, b) => a.productName.compareTo(b.productName),
          );
          break;
        case SortOption.nameDesc:
          _filteredResults.sort(
            (a, b) => b.productName.compareTo(a.productName),
          );
          break;
        case SortOption.priceAsc:
          _filteredResults.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceDesc:
          _filteredResults.sort((a, b) => b.price.compareTo(a.price));
          break;
        default:
          break;
      }
    });
  }

  Widget _buildSortButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            _buildSortChip(label: 'Tên A-Z', option: SortOption.nameAsc),
            const SizedBox(width: 8),
            _buildSortChip(label: 'Tên Z-A', option: SortOption.nameDesc),
            const SizedBox(width: 8),
            _buildSortChip(label: 'Giá tăng dần', option: SortOption.priceAsc),
            const SizedBox(width: 8),
            _buildSortChip(label: 'Giá giảm dần', option: SortOption.priceDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({required String label, required SortOption option}) {
    final isSelected = _currentSort == option;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _currentSort = selected ? option : null;
          _sortProducts();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade400 : Colors.black26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tìm kiếm sản phẩm',
          style: TextStyle(color: Colors.white), // Văn bản trắng
        ),
        backgroundColor: Colors.blue, // Nền xanh
        iconTheme: const IconThemeData(color: Colors.white), // Biểu tượng trắng
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchProducts,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Nhập từ khóa tìm kiếm...',
                        hintStyle: TextStyle(
                          color: Colors.black26,
                        ), // Gợi ý màu xanh đậm
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black38,
                        ), // Biểu tượng xanh
                        filled: true,
                        fillColor: Colors.white, // Nền trắng
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color: Colors.black,
                  ), // Biểu tượng xanh
                  onPressed: _searchResults.isEmpty ? null : _showFilterDialog,
                ),
              ],
            ),
          ),

          // Dải nút sắp xếp
          _buildSortButtons(),

          // Phần hiển thị kết quả
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ) // Vòng xoay màu xanh
                    : _filteredResults.isEmpty
                    ? const Center(
                      child: Text(
                        'Không tìm thấy sản phẩm nào',
                        style: TextStyle(color: Colors.blue), // Văn bản xanh
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final product = _filteredResults[index];
                        return GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          ProductDetailScreen(product: product),
                                ),
                              ),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.blue.shade100,
                              ), // Viền xanh nhạt
                            ),
                            color: Colors.white, // Nền trắng
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    child: Image.network(
                                      product.images.isNotEmpty
                                          ? product.images[0]
                                          : 'placeholder_image_url',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Utils.formatCurrency(product.price),
                                        style: const TextStyle(
                                          color: Colors.black, // Giá màu xanh
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
