import 'dart:io';

import 'package:ecommerce_app/models/category_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/category_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/utils/image_upload.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _brandController = TextEditingController();
  final _stockController = TextEditingController();
  final _discountController = TextEditingController();
  final _productRepo = ProductRepository();
  final _categoryRepo = CategoryRepository();
  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();
  String? _selectedCategory;
  List<CategoryModel> _categories = [];
  List<File> _selectedImages = [];
  bool _showDiscountInput = false;
  List<String> _images = [];
  List<String> _uploadedImages = [];
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProductData();
  }

  void _loadProductData() {
    _nameController.text = widget.product.productName;
    _descriptionController.text = widget.product.description;
    _priceController.text = Utils.formatCurrency(widget.product.price);
    _costPriceController.text = Utils.formatCurrency(widget.product.costPrice);
    _brandController.text = widget.product.brand;
    _stockController.text = widget.product.stock.toString();
    _discountController.text = widget.product.discount.toString();
    _selectedCategory = widget.product.categoryId;
    _selectedImages = widget.product.images.map((path) => File(path)).toList();
    _images = widget.product.images.map((url) => url).toList();
    _uploadedImages = [];
    if (widget.product.discount > 0) {
      _showDiscountInput = true;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryRepo.getParentCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> newImages =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      for (var image in newImages) {
        String uploadedUrl = await _imageUploadService.uploadImage(image);
        _uploadedImages.add(uploadedUrl);
      }
      setState(() {
        _selectedImages.addAll(newImages);
        _images.addAll(_uploadedImages);
      });
    }
  }

  void _updateProduct(BuildContext context) async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      if (_selectedImages.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng chọn ít nhất 3 hình ảnh"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double discount = double.tryParse(_discountController.text.trim()) ?? 0;
      if (discount > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giảm giá không thể vượt quá 50%"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Improved parsing for price and costPrice
      String priceText = _priceController.text;
      String costPriceText = _costPriceController.text;

      // Remove currency symbol and formatting
      priceText = priceText.replaceAll('VNĐ', '').replaceAll('.', '').trim();
      costPriceText =
          costPriceText.replaceAll('VNĐ', '').replaceAll('.', '').trim();

      // Handle any other non-numeric characters
      priceText = priceText.replaceAll(RegExp(r'[^\d]'), '');
      costPriceText = costPriceText.replaceAll(RegExp(r'[^\d]'), '');

      double price = double.tryParse(priceText) ?? 0.0;
      double costPrice = double.tryParse(costPriceText) ?? 0.0;

      final updatedProduct = ProductModel(
        id: widget.product.id,
        productName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        costPrice: costPrice,
        brand: _brandController.text.trim(),
        categoryId: _selectedCategory!,
        stock: int.parse(_stockController.text.trim()),
        discount: discount,
        images: _images,
      );

      try {
        await _productRepo.updateProduct(updatedProduct);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật sản phẩm thành công"),
              backgroundColor: Colors.green,
            ),
          );

          // Return true to indicate successful update
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi cập nhật sản phẩm: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chỉnh sửa sản phẩm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard("Tên sản phẩm & Mô tả", [
                _buildLabeledTextField("Tên sản phẩm", _nameController),
                _buildLabeledTextField("Thương hiệu", _brandController),
                _buildLabeledTextField(
                  "Mô tả sản phẩm",
                  _descriptionController,
                  minLines: 5,
                  maxLines: null,
                ),
              ]),
              _buildCard("Giá & Số lượng", [
                _buildLabeledTextField(
                  "Giá gốc sản phẩm",
                  _costPriceController,
                  keyboardType: TextInputType.number,
                  isPrice: true,
                ),
                _buildLabeledTextField(
                  "Giá bán sản phẩm",
                  _priceController,
                  keyboardType: TextInputType.number,
                ),
                _buildLabeledTextField(
                  "Số lượng trong kho",
                  _stockController,
                  keyboardType: TextInputType.number,
                ),
              ]),
              _buildCard("Danh mục", [_buildCategoryDropdown()]),
              _buildCard("Giảm giá", [
                if (!_showDiscountInput)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showDiscountInput = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors
                              .blue, // Changed from Color(0xFF7AE582) to Colors.blue
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Áp dụng giảm giá",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_showDiscountInput)
                  _buildLabeledTextField(
                    "Giảm giá (%)",
                    _discountController,
                    keyboardType: TextInputType.number,
                  ),
              ]),
              _buildCard("Hình ảnh", [_buildImagePicker()]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateProduct(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors
                            .blue, // Changed from Color(0xFF7AE582) to Colors.blue
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Cập nhật sản phẩm",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 20,
                  color: const Color(0xFF7AE582),
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    int minLines = 1,
    int? maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isPrice = false,
    bool isDiscount = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (isDiscount) {
                int discount = int.tryParse(value) ?? 0;
                if (discount > 50) {
                  controller.text = "50"; // Giới hạn tối đa 50%
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }
              if (isPrice) {
                String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                if (cleanValue.isNotEmpty) {
                  final formatter = NumberFormat("#,###", "vi_VN");
                  String formattedValue = formatter.format(
                    int.parse(cleanValue),
                  );
                  controller.value = TextEditingValue(
                    text: "$formattedValue VNĐ",
                    selection: TextSelection.collapsed(
                      offset: formattedValue.length + 4,
                    ),
                  );
                }
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Vui lòng nhập $label";
              }
              if (isDiscount) {
                int discount = int.tryParse(value) ?? 0;
                if (discount > 50) {
                  return "Giảm giá không thể vượt quá 50%";
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      items:
          _categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      decoration: const InputDecoration(border: InputBorder.none),
      validator: (value) => value == null ? "Vui lòng chọn danh mục" : null,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Chọn hình ảnh (${_selectedImages.length}/3+)",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: const Center(
                  child: Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                ),
              ),
            ),
            ..._images.map(
              (imgUrl) => Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imgUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeImage(imgUrl),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _removeImage(String image) {
    setState(() {
      _images.remove(image);
    });
  }
}
