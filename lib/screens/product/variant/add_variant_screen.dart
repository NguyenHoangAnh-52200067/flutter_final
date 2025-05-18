// import 'dart:io';

// import 'package:ecommerce_app/models/product_model.dart';
// import 'package:ecommerce_app/repository/product_repository.dart';
// import 'package:ecommerce_app/utils/image_upload.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// class AddVariantScreen extends StatefulWidget {
//   final ProductModel parentProduct;

//   const AddVariantScreen({super.key, required this.parentProduct});

//   @override
//   _AddVariantScreenState createState() => _AddVariantScreenState();
// }

// class _AddVariantScreenState extends State<AddVariantScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final ProductRepository _productRepo = ProductRepository();
//   final ImageUploadService _imageUploadService =
//       ImageUploadService.getInstance();
//   late TextEditingController _nameController;
//   late TextEditingController _priceController;
//   late TextEditingController _costPriceController;
//   late TextEditingController _stockController;

//   List<File> _selectedImages = [];
//   List<String> _images = [];
//   List<String> _imageList = [];

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _priceController = TextEditingController();
//     _stockController = TextEditingController();
//     _costPriceController = TextEditingController();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _priceController.dispose();
//     _stockController.dispose();
//     _costPriceController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImages() async {
//     final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
//     if (pickedFiles != null && pickedFiles.isNotEmpty) {
//       List<File> newImages =
//           pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

//       for (var image in newImages) {
//         String? uploadedUrl = await _imageUploadService.uploadImage(image);
//         print("Uploaded URL: $uploadedUrl");
//         _imageList.add(uploadedUrl);
//       }
//       setState(() {
//         _selectedImages.addAll(newImages);
//         _images = _imageList;
//       });
//     }
//   }

//   void _saveVariant() async {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedImages.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Vui lòng chọn ít nhất một hình ảnh cho biến thể"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       String cleanPrice = _priceController.text.trim();
//       cleanPrice = cleanPrice.replaceAll(RegExp(r'[^\d,]'), '');
//       cleanPrice = cleanPrice.replaceAll(',', '.');

//       int lastDotIndex = cleanPrice.lastIndexOf(".");
//       if (lastDotIndex != -1) {
//         String beforeDot = cleanPrice
//             .substring(0, lastDotIndex)
//             .replaceAll('.', '');
//         String afterDot = cleanPrice.substring(lastDotIndex);
//         cleanPrice = beforeDot + afterDot;
//       }

//       if (cleanPrice.isEmpty || cleanPrice == ".") {
//         cleanPrice = "0";
//       }

//       double price = double.tryParse(cleanPrice) ?? 0.0;

//       ProductModel newVariant = ProductModel(
//         parentId: widget.parentProduct.id,
//         productName: _nameController.text.trim(),
//         description: widget.parentProduct.description,
//         price: price,
//         costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
//         discount: 0.0,
//         brand: widget.parentProduct.brand,
//         categoryId: widget.parentProduct.categoryId,
//         stock: int.parse(_stockController.text.trim()),
//         images: _images,
//       );

//       await _productRepo.addVariant(widget.parentProduct, newVariant);

//       if (mounted) {
//         Navigator.pop(context, newVariant);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Thêm biến thể",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blue,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               _buildCard("Thông tin biến thể", [
//                 _buildLabeledTextField("Tên biến thể", _nameController),
//                 _buildLabeledTextField(
//                   "Giá gốc",
//                   _costPriceController,
//                   keyboardType: TextInputType.number,
//                   isPrice: true,
//                 ),
//                 _buildLabeledTextField(
//                   "Giá bán",
//                   _priceController,
//                   keyboardType: TextInputType.number,
//                   isPrice: true,
//                 ),
//                 _buildLabeledTextField(
//                   "Số lượng",
//                   _stockController,
//                   keyboardType: TextInputType.number,
//                 ),
//               ]),
//               _buildCard("Hình ảnh biến thể", [_buildImagePicker()]),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => _saveVariant(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     "Lưu biến thể",
//                     style: TextStyle(fontSize: 16, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(String title, List<Widget> children) {
//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 3,
//       margin: const EdgeInsets.only(bottom: 15),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 5,
//                   height: 20,
//                   color: Colors.blue,
//                   margin: const EdgeInsets.only(right: 10),
//                 ),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLabeledTextField(
//     String label,
//     TextEditingController controller, {
//     int minLines = 1,
//     int? maxLines = 1,
//     TextInputType keyboardType = TextInputType.text,
//     bool isPrice = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 5),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             minLines: minLines,
//             maxLines: maxLines,
//             decoration: const InputDecoration(
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 10,
//               ),
//               border: InputBorder.none,
//             ),
//             onChanged:
//                 isPrice
//                     ? (value) {
//                       String cleanValue = value.replaceAll(
//                         RegExp(r'[^\d]'),
//                         '',
//                       );
//                       if (cleanValue.isNotEmpty) {
//                         final formatter = NumberFormat("#,###", "vi_VN");
//                         String formattedValue = formatter.format(
//                           int.parse(cleanValue),
//                         );
//                         controller.value = TextEditingValue(
//                           text: "$formattedValue VNĐ",
//                           selection: TextSelection.collapsed(
//                             offset: formattedValue.length + 4,
//                           ),
//                         );
//                       }
//                     }
//                     : null,
//             validator:
//                 (value) =>
//                     value == null || value.isEmpty
//                         ? "Vui lòng nhập $label"
//                         : null,
//           ),
//         ),
//         const SizedBox(height: 10),
//       ],
//     );
//   }

//   Widget _buildImagePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Chọn hình ảnh (${_selectedImages.length}/3+)",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 10),
//         Wrap(
//           spacing: 10,
//           runSpacing: 10,
//           children: [
//             GestureDetector(
//               onTap: _pickImages,
//               child: Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: Colors.grey,
//                     style: BorderStyle.solid,
//                     width: 1.5,
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                   color: Colors.grey[100],
//                 ),
//                 child: const Center(
//                   child: Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
//                 ),
//               ),
//             ),
//             ..._selectedImages.map(
//               (file) => Stack(
//                 alignment: Alignment.topRight,
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(
//                       file,
//                       width: 80,
//                       height: 80,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => _removeImage(file),
//                     child: Container(
//                       decoration: const BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.red,
//                       ),
//                       padding: const EdgeInsets.all(4),
//                       child: const Icon(
//                         Icons.close,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   void _removeImage(File image) {
//     setState(() {
//       _selectedImages.remove(image);
//     });
//   }
// }
import 'dart:io';

import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/utils/image_upload.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; // Thêm thư viện animate_do

class AddVariantScreen extends StatefulWidget {
  final ProductModel parentProduct;

  const AddVariantScreen({super.key, required this.parentProduct});

  @override
  _AddVariantScreenState createState() => _AddVariantScreenState();
}

class _AddVariantScreenState extends State<AddVariantScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _productRepo = ProductRepository();
  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;

  List<File> _selectedImages = [];
  List<String> _images = [];
  List<String> _imageList = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _costPriceController = TextEditingController();
    _stockController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> newImages =
          pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

      for (var image in newImages) {
        String? uploadedUrl = await _imageUploadService.uploadImage(image);
        print("Uploaded URL: $uploadedUrl");
        _imageList.add(uploadedUrl);
      }
      setState(() {
        _selectedImages.addAll(newImages);
        _images = _imageList;
      });
    }
  }

  void _saveVariant() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng chọn ít nhất một hình ảnh cho biến thể"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String cleanPrice = _priceController.text.trim();
      cleanPrice = cleanPrice.replaceAll(RegExp(r'[^\d,]'), '');
      cleanPrice = cleanPrice.replaceAll(',', '.');

      int lastDotIndex = cleanPrice.lastIndexOf(".");
      if (lastDotIndex != -1) {
        String beforeDot = cleanPrice
            .substring(0, lastDotIndex)
            .replaceAll('.', '');
        String afterDot = cleanPrice.substring(lastDotIndex);
        cleanPrice = beforeDot + afterDot;
      }

      if (cleanPrice.isEmpty || cleanPrice == ".") {
        cleanPrice = "0";
      }

      double price = double.tryParse(cleanPrice) ?? 0.0;

      ProductModel newVariant = ProductModel(
        parentId: widget.parentProduct.id,
        productName: _nameController.text.trim(),
        description: widget.parentProduct.description,
        price: price,
        costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
        discount: 0.0,
        brand: widget.parentProduct.brand,
        categoryId: widget.parentProduct.categoryId,
        stock: int.parse(_stockController.text.trim()),
        images: _images,
      );

      await _productRepo.addVariant(widget.parentProduct, newVariant);

      if (mounted) {
        Navigator.pop(context, newVariant);
      }
    }
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
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
                                "Thêm biến thể",
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
                    FadeInUp(
                      duration: Duration(milliseconds: 600),
                      child: _buildCard("Thông tin biến thể", [
                        _buildLabeledTextField("Tên biến thể", _nameController),
                        _buildLabeledTextField(
                          "Giá gốc",
                          _costPriceController,
                          keyboardType: TextInputType.number,
                          isPrice: true,
                        ),
                        _buildLabeledTextField(
                          "Giá bán",
                          _priceController,
                          keyboardType: TextInputType.number,
                          isPrice: true,
                        ),
                        _buildLabeledTextField(
                          "Số lượng",
                          _stockController,
                          keyboardType: TextInputType.number,
                        ),
                      ]),
                    ),
                    FadeInUp(
                      duration: Duration(milliseconds: 700),
                      child: _buildCard("Hình ảnh biến thể", [_buildImagePicker()]),
                    ),
                    SizedBox(height: 20),
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      child: ZoomIn(
                        duration: Duration(milliseconds: 500),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _saveVariant(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Lưu biến thể",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Đệm để tránh bị che bởi bàn phím
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return FadeInUp(
      duration: Duration(milliseconds: 600),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
        ),
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ...children,
            ],
          ),
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
  }) {
    return SlideInUp(
      duration: Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976D2),
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFBBDEFB), width: 1),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              minLines: minLines,
              maxLines: maxLines,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
              ),
              onChanged: isPrice
                  ? (value) {
                      String cleanValue = value.replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
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
                  : null,
              validator: (value) =>
                  value == null || value.isEmpty ? "Vui lòng nhập $label" : null,
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return FadeInUp(
      duration: Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chọn hình ảnh (${_selectedImages.length}/3+)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976D2),
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ZoomIn(
                duration: Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFF2196F3),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[100],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        color: Color(0xFF2196F3),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              ..._selectedImages.map(
                (file) => ZoomIn(
                  duration: Duration(milliseconds: 500),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeImage(file),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }
}