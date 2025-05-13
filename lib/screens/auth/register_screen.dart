import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/address_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/auth/login_screen.dart';
import 'package:ecommerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecommerce_app/screens/widgets/button_input/input_field.dart';
import 'package:ecommerce_app/services/address_api_service.dart';
import 'package:ecommerce_app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';

// FIREBASE
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:uuid/uuid.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UserRepository _userRepo = UserRepository();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final cfpasswordController = TextEditingController();
  final AddressRepository _addressRepository = AddressRepository();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _email = FocusNode();
  final FocusNode _password = FocusNode();
  final FocusNode _cfpassword = FocusNode();
  final String apiKey = 'KeONrT42qDbhvyFK5oLjywhE0EAcrxeHh0NTznDz';

  List<dynamic> _suggestions = [];
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController wardController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController localController = TextEditingController();
  final AddressApiService addressApiService = AddressApiService();
  final Uuid uuid = Uuid();

  bool _obscureTextPassword = true;
  bool _obscureTextCFPassword = true;
  bool _isSigningUp = false;
  final List<AddressModel> _addresses = [];

  String city = "";
  String district = "";
  String ward = "";
  String street = "";
  String local = "";

  void _saveAddress(String userId) async {
    AddressModel newAddress = AddressModel(
      addressId: uuid.v4(),
      isDefault: true,
      userId: userId,
      city: city,
      district: district,
      ward: ward,
      street: street,
      local: local,
      fullAddress: addressController.text,
      userName: _fullNameController.text,
      userPhone: _emailController.text,
      userMail: _emailController.text,
    );

    _addressRepository.saveAddress(newAddress);
    _addresses.add(newAddress);
    setState(() {});
  }

  void _onSearchChanged(String query) {
    addressApiService.debounceSearch(query, (suggestions) {
      setState(() {
        _suggestions = suggestions;
      });
    });
  }

  Future<void> fetchAddressDetails(String placeId) async {
    final response = await http.get(
      Uri.parse(
        'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['result'] != null) {
        final result = data['result'];

        String fullAddress = result['formatted_address'] ?? '';
        List<String> addressParts = fullAddress.split(',');
        String localAddress = result['name'] ?? '';

        setState(() {
          city = addressParts.length > 2 ? addressParts.last.trim() : '';
          district =
              addressParts.length > 1
                  ? addressParts[addressParts.length - 2].trim()
                  : '';
          ward =
              addressParts.isNotEmpty
                  ? addressParts[addressParts.length - 3].trim()
                  : '';
          street = addressParts.isNotEmpty ? addressParts[1].trim() : '';
          local = localAddress;
        });
      }
    } else {
      print('Lỗi khi lấy dữ liệu địa chỉ');
    }
  }

  void _signUpScreen() async {
    setState(() {
      _isSigningUp = true;
    });
    String email = _emailController.text.trim();
    String fullName = _fullNameController.text.trim();
    String password = _passwordController.text;

    try {
      User? user = await _auth.createUserWithEmailAndPassword(
        context: context,
        email: email,
        password: password,
      );

      if (user != null) {
        print("User created successfully");
        _saveAddress(user.uid);
        UserModel newUser = UserModel(
          id: user.uid,
          fullName: fullName,
          email: email,
          linkImage: "",
        );

        await _userRepo.createUser(context, newUser);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print("Lỗi tại vì: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký thất bại: $e")));
    }

    setState(() {
      _isSigningUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80.0, right: 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bạn đã có tài khoản?',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7AE582),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(70, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: width,
                    height: height / 1.25,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7AE582),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 160.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HA SHOP',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Text(
                                  'Tạo tài khoản để mua sắm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              InputField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (String? value) {
                                  final RegExp emailRegExp = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  );
                                  if (!emailRegExp.hasMatch(value ?? '')) {
                                    _email.requestFocus();
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              InputField(
                                controller: _fullNameController,
                                hintText: "Họ tên",
                                icon: Icons.person,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập họ tên';
                                  } else if (value.trim().length < 2) {
                                    return 'Họ tên quá ngắn';
                                  }
                                  return null;
                                },
                              ),

                              // Address input field with suggestions
                              SizedBox(
                                width: 365,
                                child: TextField(
                                  controller: addressController,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Địa chỉ",
                                    prefixIcon: Icon(Icons.location_on),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                              if (_suggestions.isNotEmpty)
                                Positioned(
                                  top: 67,
                                  left: 25,
                                  right: 25,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children:
                                              _suggestions.map((suggestion) {
                                                return ListTile(
                                                  title: Text(
                                                    suggestion['description'],
                                                  ),
                                                  onTap: () {
                                                    addressController.text =
                                                        suggestion['description'];
                                                    fetchAddressDetails(
                                                      suggestion['place_id'],
                                                    );
                                                    setState(() {
                                                      _suggestions = [];
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              InputField(
                                controller: _phoneController,
                                hintText: 'Số điện thoại',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                isPassword: true,

                                // validator: (String? value) {
                                //   if (value == null || value.length < 6) {
                                //     _password.requestFocus();
                                //     return "Password should have at least 6 characters";
                                //   }
                                //   return null;
                                // },
                              ),
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////
                              InputField(
                                controller: _passwordController,
                                focusNode: _password,
                                hintText: 'Mật khẩu',
                                icon: Icons.lock,
                                obscureText: _obscureTextPassword,
                                isPassword: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureTextPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureTextPassword =
                                          !_obscureTextPassword;
                                    });
                                  },
                                ),
                                validator: (String? value) {
                                  if (value == null || value.length < 6) {
                                    _password.requestFocus();
                                    return "Password should have at least 6 characters";
                                  }
                                  return null;
                                },
                              ),

                              InputField(
                                controller: cfpasswordController,
                                focusNode: _cfpassword,
                                hintText: 'Nhập lại mật khẩu',
                                icon: Icons.lock,
                                obscureText: _obscureTextCFPassword,
                                isPassword: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureTextCFPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureTextCFPassword =
                                          !_obscureTextCFPassword;
                                    });
                                  },
                                ),
                                validator: (String? value) {
                                  if (value == null || value.length < 6) {
                                    _cfpassword.requestFocus();
                                    return "Password should have at least 6 characters";
                                  } else if (value !=
                                      _passwordController.text) {
                                    _cfpassword.requestFocus();
                                    return "Confirm password does not match";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              CustomButton(
                                text: 'Đăng ký',
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _signUpScreen();
                                  }
                                },
                                isLoading: _isSigningUp,
                                padding: const EdgeInsets.only(
                                  left: 24.0,
                                  right: 24.0,
                                  bottom: 24.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
