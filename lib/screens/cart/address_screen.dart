import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/address_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/cart/edit_address_screen.dart';
import 'package:ecommerce_app/screens/cart/new_address_screen.dart';
import 'package:flutter/material.dart';

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  final AddressRepository _addressRepository = AddressRepository();
  UserModel? userModel;

  int selectedAddressIndex = 0;
  List<AddressModel> addressList = [];
  bool _isUpdatingAddress = false;

  // Khởi tạo animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  void _setDefaultAddress(int index) async {
    if (_isUpdatingAddress) return;

    setState(() {
      _isUpdatingAddress = true;
    });

    try {
      String selectedId = addressList[index].addressId;

      for (var addr in addressList) {
        if (addr.isDefault) {
          await _addressRepository.updateDefaultAddress(addr.addressId, false);
        }
      }

      await _addressRepository.updateDefaultAddress(selectedId, true);

      setState(() {
        for (int i = 0; i < addressList.length; i++) {
          addressList[i] = AddressModel(
            addressId: addressList[i].addressId,
            userId: addressList[i].userId,
            city: addressList[i].city,
            district: addressList[i].district,
            ward: addressList[i].ward,
            street: addressList[i].street,
            local: addressList[i].local,
            fullAddress: addressList[i].fullAddress,
            userName: addressList[i].userName,
            userPhone: addressList[i].userPhone,
            isDefault: (i == index),
            userMail: addressList[i].userMail,
          );
        }
        selectedAddressIndex = index;
      });
    } catch (e) {
      print("Lỗi khi cập nhật địa chỉ mặc định: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể cập nhật địa chỉ: $e"),
          backgroundColor: Colors.blue, // Màu xanh dương
        ),
      );
    } finally {
      setState(() {
        _isUpdatingAddress = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUser();

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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      String userId = await _userRepository.getEffectiveUserId();
      final addresses = await _addressRepository.getAddressesByUserId(userId);

      setState(() {
        addressList = addresses;
        int defaultIndex = addresses.indexWhere((addr) => addr.isDefault);
        selectedAddressIndex = defaultIndex >= 0 ? defaultIndex : 0;
      });
    } catch (e) {
      print("Lỗi khi tải thông tin người dùng: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể tải thông tin địa chỉ"),
          backgroundColor: Colors.blue, // Màu xanh dương
        ),
      );
    }
  }

  void _editAddress(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(address: addressList[index]),
      ),
    ).then((_) => fetchUser());
  }

  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewAddressScreen()),
    );

    if (result == true) {
      await fetchUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chọn địa chỉ nhận hàng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Màu trắng
          onPressed: () => Navigator.pop(context, true),
        ),
        backgroundColor: Colors.blue, // Màu xanh dương cho AppBar
        elevation: 0,
      ),
      backgroundColor: Colors.white, // Nền trắng
      body: Column(
        children: [
          Expanded(
            child:
                addressList.isEmpty
                    ? Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          "Chưa có địa chỉ nào. Vui lòng thêm địa chỉ mới.",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ), // Màu xanh đậm
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: addressList.length,
                      itemBuilder: (context, index) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.blue.shade300,
                                ), // Viền xanh nhạt
                              ),
                              elevation: 3,
                              color: Colors.white,
                              child: InkWell(
                                onTap:
                                    _isUpdatingAddress
                                        ? null
                                        : () => _setDefaultAddress(index),
                                child: ListTile(
                                  leading: Radio<int>(
                                    value: index,
                                    groupValue: selectedAddressIndex,
                                    onChanged:
                                        _isUpdatingAddress
                                            ? null
                                            : (int? value) {
                                              if (value != null) {
                                                _setDefaultAddress(value);
                                              }
                                            },
                                    activeColor:
                                        Colors.blue, // Màu xanh dương khi chọn
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          addressList[index].userName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors
                                                    .blue
                                                    .shade700, // Màu xanh đậm
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          softWrap: true,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _editAddress(index);
                                        },
                                        child: Text(
                                          "Sửa",
                                          style: TextStyle(
                                            color: Colors.blue,
                                          ), // Màu xanh dương
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addressList[index].fullAddress,
                                        style: TextStyle(
                                          color: Colors.black87, // Màu chữ phụ
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        softWrap: true,
                                      ),
                                      if (addressList[index].isDefault == true)
                                        Container(
                                          margin: EdgeInsets.only(top: 6),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: Text(
                                            "Mặc định",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Divider(color: Colors.blue.shade300), // Đường phân cách xanh nhạt
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                onPressed: _addNewAddress,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Thêm Địa Chỉ Mới",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Màu xanh dương
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
