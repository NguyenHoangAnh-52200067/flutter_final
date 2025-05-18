import 'dart:io';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/address_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/services/address_api_service.dart';
import 'package:ecommerce_app/utils/image_upload.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final UserRepository _userRepo = UserRepository();
  final AddressRepository _addressRepository = AddressRepository();
  final AddressApiService _addressApiService = AddressApiService();
  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<String> _addressSug = [];
  String? _email;
  String? _linkImage;
  bool _isEditing = false;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _imageLoadController;
  late Animation<double> _imageLoadAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Fade animation cho toàn bộ giao diện
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Scale animation cho các nút
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _scaleController.forward();
      }
    });
    _scaleController.forward();

    // Animation cho hiệu ứng loading ảnh
    _imageLoadController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _imageLoadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageLoadController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _imageLoadController.dispose();
    super.dispose();
  }

  void _fetchUserData() async {
    if (user == null) return;

    try {
      UserModel? userModel = await _userRepo.getUserDetails(user!.uid);
      if (userModel != null) {
        final address = await _addressRepository.getAddressesByUserId(
          userModel.id!,
        );
        setState(() {
          _email = userModel.email;
          _fullNameController.text = userModel.fullName;
          _addressController.text = address.firstOrNull!.fullAddress;
          _linkImage = userModel.linkImage;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy dữ liệu người dùng")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    File newImage = File(pickedFile.path);
    final linkImage = await _imageUploadService.uploadImage(newImage);

    setState(() {
      _linkImage = linkImage;
      _isLoading = false;
    });

    await _updateUserImage(_linkImage!);
  }

  Future<void> _updateUserImage(String imagePath) async {
    try {
      if (user != null) {
        UserModel updatedUser = UserModel(
          id: user!.uid,
          email: _email!,
          fullName: _fullNameController.text.trim(),
          address: _addressController.text.trim(),
          linkImage: imagePath,
        );

        await _userRepo.updateUser(user!.uid, updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đại diện đã được cập nhật!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật ảnh: $e')));
    }
  }

  void _onAddressChanged(String address) {
    print("DIA CHI NHAP: $address");
    _addressApiService.deplayedSearchReq(address, (onResult) {
      setState(() {
        _addressController.text = address;
        _addressSug = onResult;
      });
      print("Dia chi goi y: $onResult");
    });
  }

  void _updateUserData() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserModel updatedUser = UserModel(
        id: user!.uid,
        email: _email!,
        fullName: _fullNameController.text.trim(),
        address: _addressController.text.trim(),
        linkImage: _linkImage,
      );

      await _userRepo.updateUser(user!.uid, updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEmailField() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: TextEditingController(text: _email),
              keyboardType: TextInputType.emailAddress,
              enabled: false,
              style: TextStyle(color: Colors.grey[600]),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscure,
    VoidCallback toggleObscure,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isObscure,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blueAccent,
                  ),
                  onPressed: toggleObscure,
                ),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _isEditing ? Colors.white : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: _isEditing,
              readOnly: !_isEditing,
              style: TextStyle(
                color: _isEditing ? Colors.black87 : Colors.grey[600],
                fontSize: 16,
              ),
              onChanged: onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    margin: const EdgeInsets.only(right: 12),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          "Hồ Sơ Cá Nhân",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            _isLoading
                                ? Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      RotationTransition(
                                        turns: _imageLoadAnimation,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: SweepGradient(
                                              colors: [
                                                Colors.blueAccent,
                                                Colors.blue[200]!,
                                                Colors.blueAccent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.cloud_upload,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ],
                                  ),
                                )
                                : ImageUtils.buildImage(_linkImage),
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCard("Email", [_buildEmailField()]),
                _buildCard("Thông Tin Cá Nhân", [
                  _buildLabeledTextField("Họ và Tên", _fullNameController),
                  Stack(
                    children: [
                      _buildLabeledTextField(
                        "Địa Chỉ",
                        _addressController,
                        onChanged: _onAddressChanged,
                      ),
                      if (_addressSug.isNotEmpty)
                        Positioned(
                          top: 80,
                          left: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children:
                                      _addressSug.map((suggestion) {
                                        return Material(
                                          color: Colors.transparent,
                                          child: ListTile(
                                            title: Text(
                                              suggestion,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            onTap: () {
                                              _addressController.text =
                                                  suggestion;
                                              setState(() {
                                                _addressSug = [];
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),
                _isEditing
                    ? Column(
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      )
                                      : const Text(
                                        "Lưu Thay Đổi",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          child: const Text(
                            "Hủy",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                    : ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                          ),
                          child: const Text(
                            "Chỉnh Sửa Thông Tin",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
