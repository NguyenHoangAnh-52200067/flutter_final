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

class _AddressScreenState extends State<AddressScreen> {
  final UserRepository _userRepository = UserRepository();
  final AddressRepository _addressRepository = AddressRepository();
  UserModel? userModel;

  int selectedAddressIndex = 0;
  List<AddressModel> addressList = [];
  bool _isUpdatingAddress = false;

  void _setDefaultAddress(int index) async {
    // Kiểm tra nếu đang trong quá trình cập nhật thì không thực hiện
    if (_isUpdatingAddress) return;

    // Đánh dấu đang trong quá trình cập nhật
    setState(() {
      _isUpdatingAddress = true;
    });

    try {
      String selectedId = addressList[index].addressId;

      // Tìm địa chỉ mặc định hiện tại và cập nhật thành false
      for (var addr in addressList) {
        if (addr.isDefault) {
          await _addressRepository.updateDefaultAddress(addr.addressId, false);
        }
      }

      // Cập nhật địa chỉ được chọn thành mặc định
      await _addressRepository.updateDefaultAddress(selectedId, true);

      // Cập nhật UI
      setState(() {
        for (int i = 0; i < addressList.length; i++) {
          // Tạo bản sao của địa chỉ để tránh lỗi với final fields
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
      // Hiển thị thông báo lỗi cho người dùng
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể cập nhật địa chỉ: $e")));
    } finally {
      // Đánh dấu đã hoàn thành quá trình cập nhật
      setState(() {
        _isUpdatingAddress = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  @override
  void dispose() {
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
        SnackBar(content: Text("Không thể tải thông tin địa chỉ")),
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
        title: Text("Chọn địa chỉ nhận hàng"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                addressList.isEmpty
                    ? Center(
                      child: Text(
                        "Chưa có địa chỉ nào. Vui lòng thêm địa chỉ mới.",
                      ),
                    )
                    : ListView.builder(
                      itemCount: addressList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                  ),
                                  // if (addressList.length > 1 &&
                                  //     selectedAddressIndex != index)
                                  TextButton(
                                    onPressed: () {
                                      _editAddress(index);
                                    },
                                    child: Text(
                                      "Sửa",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addressList[index].fullAddress,
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        59,
                                        59,
                                        59,
                                      ),
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
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        "Mặc định",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton.icon(
              onPressed: _addNewAddress,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Thêm Địa Chỉ Mới"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// void _showConfrim() {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text('Xác nhận'),
//         content: Text('Bạn có muốn xóa địa chỉ này hay không?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Không', style: TextStyle(fontSize: 18)),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               _deleteAddress(index);
//               await fetchUser();
//             },
//             child: Text(
//               'Đồng ý',
//               style: TextStyle(color: Colors.red, fontSize: 18),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }
