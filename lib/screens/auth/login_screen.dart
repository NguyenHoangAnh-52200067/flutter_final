import 'package:ecommerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecommerce_app/screens/widgets/button_input/input_field.dart';
import 'package:flutter/material.dart';
// SCREEN
import 'package:ecommerce_app/home.dart';
import 'package:ecomerce_app/screens/auth/forgot_password_screen.dart';
import 'package:ecomerce_app/screens/auth/register_screen.dart';
import 'package:ecomerce_app/screens/admin/admin_home_screen.dart';
// LIB
import 'package:flutter_social_button/flutter_social_button.dart';
// FIREBASE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureTextPassword = true;
  bool _isSigning = false;
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSigning = false;
      });
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email == "admin@gmail.com" && password == "admin123") {
      await _auth.setLoggedIn(true);
      await _auth.setUserRole('admin');
      _navigateToScreen(const AdminHomeScreen(), "Đăng nhập Admin thành công!");
      return;
    }

    User? user = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (user != null) {
      await _auth.setLoggedIn(true);
      await _auth.setUserRole('user');
      _navigateToScreen(const HomeScreen(), "Đăng nhập thành công!");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thông tin không chính xác! Vui lòng kiểm tra lại"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Some error happened");
    }

    setState(() {
      _isSigning = false;
    });
  }

  void _navigateToScreen(Widget screen, String message) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Container(
          height: height,
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
                        'Bạn chưa có tài khoản?',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      CustomButton(
                        text: "Đăng ký",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpScreen()),
                          );
                        },
                        backgroundColor: const Color(0xFF7AE582),
                        textColor: Colors.white,
                        fontSize: 12,
                        height: 32,
                        width: 100,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: width,
                  height: height / 1.4,
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
                padding: const EdgeInsets.only(top: 100.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'HA SHOP',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // const SizedBox(height: 10),
                      const Text(
                        'Mua sắm - Giá tốt - Mỗi ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            InputField(
                              controller: _emailController,
                              focusNode: _focusNodeEmail,
                              hintText: "Nhập email",
                              icon: Icons.email,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final RegExp emailRegExp = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+$',
                                );
                                if (!emailRegExp.hasMatch(value ?? '')) {
                                  _focusNodeEmail.requestFocus();
                                  return 'Email không hợp lệ!';
                                }
                                return null;
                              },
                            ),
                            InputField(
                              controller: _passwordController,
                              focusNode: _focusNodePassword,
                              hintText: "Nhập mật khẩu",
                              icon: Icons.lock,
                              isPassword: true,
                              obscureText: _obscureTextPassword,
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
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  _focusNodePassword.requestFocus();
                                  return "Mật khẩu phải có ít nhất 6 ký tự!";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomButton(
                              text: "Đăng nhập",
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _signIn();
                                }
                              },
                              isLoading: _isSigning,
                              padding: const EdgeInsets.only(
                                left: 24.0,
                                right: 24.0,
                                bottom: 24.0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 24.0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ForgotPassword(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Bạn quên mật khẩu?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            // UX UI Other LoginScreen
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 40.0,
                                right: 40.0,
                                top: 24,
                                bottom: 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      'Đăng nhập với',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FlutterSocialButton(
                                  onTap: () {},
                                  buttonType: ButtonType.facebook,
                                  mini: true,
                                  iconSize: 15,
                                ),
                                const SizedBox(width: 12),
                                FlutterSocialButton(
                                  onTap: () {},
                                  buttonType: ButtonType.google,
                                  mini: true,
                                  iconSize: 15,
                                ),
                                const SizedBox(width: 12),
                                FlutterSocialButton(
                                  onTap: () {},
                                  buttonType: ButtonType.linkedin,
                                  mini: true,
                                  iconSize: 15,
                                ),
                              ],
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
    );
  }
}
