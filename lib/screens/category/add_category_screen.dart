import 'package:ecomerce_app/models/category_model.dart';
import 'package:ecomerce_app/repository/category_repository.dart';
import 'package:ecomerce_app/utils/image_upload.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  const AddCategoryScreen({super.key, this.category});

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();
  File? _imageFile;
  bool isEditing = false;
  String? _imageUrl;
  List<String> _images = [];
  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      isEditing = true;
      _nameController.text = widget.category!.name;
      if (widget.category!.imageUrl != null &&
          widget.category!.imageUrl!.isNotEmpty) {
        _imageFile = File(widget.category!.imageUrl!);
        _imageUrl = widget.category!.imageUrl;
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    List<File> newImages = [File(pickedFile.path)];
    for (var image in newImages) {
      String? uploadedUrl = await _imageUploadService.uploadImage(image);
      _images.add(uploadedUrl);
      _imageUrl = uploadedUrl;
    }
    setState(() {
      _imageFile = newImages.first;
    });
  }

  void _addCategory() async {
    if (_formKey.currentState!.validate()) {
      final category = CategoryModel(
        name: _nameController.text.trim(),
        imageUrl: _images.first,
      );

      await _categoryRepo.addCategory(context, category);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _updateCategory() async {
    if (_formKey.currentState!.validate()) {
      final updatedCategory = widget.category!.copyWith(
        name: _nameController.text.trim(),
        imageUrl: _imageUrl,
      );

      await _categoryRepo.updateCategory(context, updatedCategory);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(isEditing ? "Chỉnh sửa danh mục" : "Thêm danh mục"),
        backgroundColor: const Color(0xFF7AE582),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard("Tên danh mục", [
                _buildLabeledTextField("Tên danh mục", _nameController),
              ]),
              _buildCard("Hình ảnh danh mục", [_buildImagePicker()]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEditing ? _updateCategory : _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AE582),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Lưu thay đổi" : "Thêm danh mục",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
    TextEditingController controller,
  ) {
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
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? "Vui lòng nhập $label"
                        : null,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "* Không bắt buộc",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    _imageFile == null
                        ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Chọn ảnh danh mục",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                        : Image.network(
                          _imageUrl!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
