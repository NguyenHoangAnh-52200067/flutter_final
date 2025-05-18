import 'dart:io';

import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/utils/image_upload.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateUserProfileDialog extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onProfileUpdated;

  const UpdateUserProfileDialog({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    UserModel user,
    Function(UserModel) onProfileUpdated,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateUserProfileDialog(
          user: user,
          onProfileUpdated: onProfileUpdated,
        );
      },
    );
  }

  @override
  State<UpdateUserProfileDialog> createState() =>
      _UpdateUserProfileDialogState();
}

class _UpdateUserProfileDialogState extends State<UpdateUserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userRepo = UserRepository();
  final _fullNameController = TextEditingController();
  final _imageUploadService = ImageUploadService.getInstance();

  String? _linkImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user.fullName;
    _linkImage = widget.user.linkImage;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;
    final linkImage = await _imageUploadService.uploadImage(
      File(pickedFile.path),
    );
    setState(() {
      _linkImage = linkImage;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserModel updatedUser = UserModel(
        id: widget.user.id,
        email: widget.user.email,
        fullName: _fullNameController.text.trim(),
        linkImage: _linkImage,
        memberShipPoint: widget.user.memberShipPoint,
        memberShipCurrentPoint: widget.user.memberShipCurrentPoint,
        memberShipLevel: widget.user.memberShipLevel,
      );

      final result = await _userRepo.updateUser(widget.user.id!, updatedUser);

      if (result != null) {
        _showErrorMessage(result);
        return;
      }

      widget.onProfileUpdated(updatedUser);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      }
    } catch (e) {
      _showErrorMessage('Lỗi cập nhật: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Cập nhật thông tin',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Profile Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: ImageUtils.buildImage(_linkImage),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field (Read-only)
                TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
