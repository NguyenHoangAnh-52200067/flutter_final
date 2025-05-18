import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/repository/address_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/services/address_api_service.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel address;
  const EditAddressScreen({super.key, required this.address});

  @override
  _EditAddressScreenState createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController wardController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController localController = TextEditingController();
  final TextEditingController mailController = TextEditingController();

  final AddressApiService addressApiService = AddressApiService();
  final UserRepository _userRepository = UserRepository();
  final AddressRepository _addressRepository = AddressRepository();
  final String apiKey = 'KeONrT42qDbhvyFK5oLjywhE0EAcrxeHh0NTznDz';
  final Uuid uuid = Uuid();
  late AddressModel? address;
  bool isDefault = false;
  List<dynamic> _suggestions = [];
  bool isAddressSelected = false;
  bool _isLoading = false;

  // Khởi tạo animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    address = widget.address;
    if (address != null) {
      nameController.text = address!.userName;
      phoneController.text = address!.userPhone;
      addressController.text = address!.fullAddress;
      cityController.text = address!.city;
      districtController.text = address!.district;
      wardController.text = address!.ward;
      streetController.text = address!.street!;
      localController.text = address!.local!;
      mailController.text = address!.userMail;
      isDefault = address!.isDefault;
    }

    // Khởi tạo animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    districtController.dispose();
    wardController.dispose();
    streetController.dispose();
    localController.dispose();
    mailController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    String? userId;
    try {
      userId = await _userRepository.getEffectiveUserId();
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      userId = null;
    }

    final AddressModel updateAddress = AddressModel(
      addressId: address!.addressId,
      userId: userId,
      city: cityController.text,
      district: districtController.text,
      ward: wardController.text,
      street: streetController.text,
      local: localController.text,
      fullAddress: addressController.text,
      userName: nameController.text,
      userPhone: phoneController.text,
      isDefault: isDefault,
      userMail: mailController.text,
    );

    try {
      await _addressRepository.updateAddress(address!.addressId, updateAddress);

      if (userId != null) {
        await _addressRepository.getAddressesByUserId(userId);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Lỗi khi lưu địa chỉ: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.of(context).pop();
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 50,
              ), // Đổi màu xanh dương
              SizedBox(height: 16),
              Text(
                'Chỉnh sửa địa chỉ thành công!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ), // Đổi màu xanh dương
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAlertDialog({String message = 'Vui lòng điền thông tin đầy đủ!'}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Thông báo',
            style: TextStyle(color: Colors.blue),
          ), // Đổi màu xanh dương
          content: Text(message, style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ), // Đổi màu xanh dương
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Lỗi',
            style: TextStyle(color: Colors.blue),
          ), // Đổi màu xanh dương
          content: Text(message, style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ), // Đổi màu xanh dương
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    addressApiService.debounceSearch(query, (suggestions) {
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          isAddressSelected = false;
        });
      }
    });
  }

  Future<void> fetchAddressDetails(String placeId) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          _processAddressData(data['result']);
        } else {
          _showErrorDialog('Không tìm thấy thông tin địa chỉ');
        }
      } else {
        _showErrorDialog('Lỗi khi lấy dữ liệu địa chỉ: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Lỗi kết nối: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processAddressData(Map<String, dynamic> result) {
    String fullAddress = result['formatted_address'] ?? '';
    List<String> addressParts = fullAddress.split(',');
    String local = result['name'] ?? '';

    if (mounted) {
      setState(() {
        cityController.text =
            addressParts.length > 2 ? addressParts.last.trim() : '';
        districtController.text =
            addressParts.length > 1
                ? addressParts[addressParts.length - 2].trim()
                : '';
        wardController.text =
            addressParts.length > 2
                ? addressParts[addressParts.length - 3].trim()
                : '';
        streetController.text =
            addressParts.length > 1 ? addressParts[1].trim() : '';
        localController.text = local;
        isAddressSelected = true;
      });
    }

    if (cityController.text.isEmpty ||
        districtController.text.isEmpty ||
        wardController.text.isEmpty ||
        streetController.text.isEmpty) {
      _showAlertDialog(
        message:
            'Không thể tự động điền đầy đủ thông tin địa chỉ. Vui lòng kiểm tra lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa địa chỉ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue, // Màu xanh dương cho AppBar
        elevation: 0,
      ),
      backgroundColor: Colors.white, // Nền trắng
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: nameController,
                        labelText: "Họ và tên",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: phoneController,
                        labelText: "Số điện thoại",
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: mailController,
                        labelText: "Email",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildAddressSearchField(),
                      if (isAddressSelected) _buildAddressDetailFields(),
                      SizedBox(height: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildDeleteButton()),
                              SizedBox(width: 20),
                              Expanded(child: _buildSubmitButton()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue,
                  ), // Màu xanh dương
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.blue.shade300,
        ), // Màu xanh nhạt cho nhãn
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 2,
          ), // Viền xanh đậm khi focus
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildAddressSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFormField(
          controller: addressController,
          labelText: "Địa chỉ",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập địa chỉ';
            }
            return null;
          },
          onChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade300,
                ), // Viền xanh nhạt
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: Text(
                      suggestion['description'],
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ), // Màu xanh đậm
                    ),
                    onTap: () {
                      addressController.text = suggestion['description'];
                      fetchAddressDetails(suggestion['place_id']);
                      setState(() {
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressDetailFields() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: cityController,
          labelText: "Tỉnh / Thành phố",
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: districtController,
          labelText: "Quận / Huyện",
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: wardController,
          labelText: "Phường / Xã",
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: streetController,
          labelText: "Tên đường / Khu vực",
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: localController,
          labelText: "Tên địa điểm",
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Màu xanh dương
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: const Text(
          "LƯU THAY ĐỔI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue, // Màu chữ xanh dương
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue), // Viền xanh dương
          ),
          elevation: 5,
        ),
        child: const Text(
          "XÓA ĐỊA CHỈ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(color: Colors.blue),
          ), // Màu xanh dương
          content: const Text(
            'Bạn có chắc chắn muốn xóa địa chỉ này?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ), // Màu xanh dương
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAddress();
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAddress() async {
    setState(() => _isLoading = true);

    try {
      if (address == null) {
        throw Exception('Address is null');
      }
      if (address!.isDefault) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'Không thể xóa địa chỉ mặc định!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ), // Màu xanh dương
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.blue),
                  ), // Màu xanh dương
                ),
              ],
            );
          },
        );
        return;
      }
      await _addressRepository.deleteUserAddress(address!.addressId);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Địa chỉ đã được xóa thành công'),
            backgroundColor: Colors.blue, // Màu xanh dương
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Lỗi khi xóa địa chỉ: ${e.toString()}');
      }
    }
  }
}
