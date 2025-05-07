import 'package:flutter/material.dart';
import 'package:ecomerce_app/models/product_model.dart';
import 'package:ecomerce_app/repository/product_repository.dart';
import 'package:ecomerce_app/screens/product/product_detail_screen.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:ecomerce_app/repository/category_repository.dart';

enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc }

class SearchProductScreen extends StatefulWidget {
  const SearchProductScreen({super.key});

  @override
  State<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen> {
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

  // Thêm biến để theo dõi tùy chọn sắp xếp hiện tại
  SortOption? _currentSort;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        // Thương hiệu (Bắt buộc)
                        const Text(
                          'Thương hiệu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedBrand,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          hint: const Text('Chọn thương hiệu'),
                          items:
                              _brands.map((brand) {
                                return DropdownMenuItem(
                                  value: brand,
                                  child: Text(brand),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedBrand = value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Khoảng giá (Bắt buộc)
                        const Text(
                          'Khoảng giá',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Giá từ',
                                  contentPadding: EdgeInsets.symmetric(
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
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Đến',
                                  contentPadding: EdgeInsets.symmetric(
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          hint: const Text('Chọn danh mục'),
                          items:
                              _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _selectedRating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _selectedRating.toString(),
                          onChanged: (value) {
                            setState(() => _selectedRating = value);
                          },
                        ),
                        Text(
                          'Từ ${_selectedRating.toInt()} sao trở lên',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
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
                            backgroundColor: Colors.grey[300],
                          ),
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // if (_selectedBrand == null ||
                            //     _minPriceController.text.isEmpty ||
                            //     _maxPriceController.text.isEmpty) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(
                            //       content: Text(
                            //         'Vui lòng chọn thương hiệu và nhập khoảng giá',
                            //       ),
                            //     ),
                            //   );
                            //   return;
                            // }
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7AE582),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(color: Colors.white),
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

  // Thêm phương thức để sắp xếp sản phẩm
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

  // Thêm widget để hiển thị các nút sắp xếp
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
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF7AE582),
      checkmarkColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm sản phẩm'),
        backgroundColor: const Color(0xFF7AE582),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchProducts,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khóa tìm kiếm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _searchResults.isEmpty ? null : _showFilterDialog,
                ),
              ],
            ),
          ),

          // Thêm dải nút sắp xếp
          _buildSortButtons(),

          // Phần hiển thị kết quả
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredResults.isEmpty
                    ? const Center(child: Text('Không tìm thấy sản phẩm nào'))
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
                            ),
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Utils.formatCurrency(product.price),
                                        style: const TextStyle(
                                          color: Colors.red,
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
    super.dispose();
  }
}
