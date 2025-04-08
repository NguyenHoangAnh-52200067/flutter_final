import 'package:ecomerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecomerce_app/services/address_api_service.dart';
import 'package:flutter/material.dart';
// SCREEN
import 'package:ecomerce_app/screens/auth/login_screen.dart';
// WIDGET
import 'package:ecomerce_app/screens/widgets/form/address_form.dart';
import 'package:ecomerce_app/screens/widgets/button_input/input_field.dart';
// MODEL REPO
import 'package:ecomerce_app/models/user_model.dart';
import 'package:ecomerce_app/repository/user_repository.dart';
// FIREBASE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecomerce_app/services/firebase_auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UserRepository _userRepo = UserRepository();
  final AddressApiService _addressApiService = AddressApiService();

  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final cfpasswordController = TextEditingController();
  List<String> _addressSug = [];

  final _formKey = GlobalKey<FormState>();
  final FocusNode _email = FocusNode();
  final FocusNode _password = FocusNode();
  final FocusNode _cfpassword = FocusNode();

  bool _obscureTextPassword = true;
  bool _obscureTextCFPassword = true;
  bool _isSigningUp = false;

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

  void _signUpScreen() async {
    setState(() {
      _isSigningUp = true;
    });
    String email = _emailController.text.trim();
    String fullName = _fullNameController.text.trim();
    String password = _passwordController.text;
    String address = _addressController.text.trim();

    try {
      User? user = await _auth.createUserWithEmailAndPassword(
        context: context,
        email: email,
        password: password,
      );

      if (user != null) {
        print("User created successfully");

        UserModel newUser = UserModel(
          id: user.uid,
          fullName: fullName,
          email: email,
          address: address,
          linkImage: "",
        );
        await _userRepo.createUser(context, newUser);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print("Error: $e");
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
                              InputField(
                                controller: _addressController,
                                hintText: 'Địa chỉ',
                                icon: Icons.map,
                                onChanged: _onAddressChanged,
                              ),
                              if (_addressSug.isNotEmpty)
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
                                              _addressSug.map((suggestion) {
                                                return Material(
                                                  color: Colors.transparent,
                                                  child: ListTile(
                                                    title: Text(suggestion),
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
