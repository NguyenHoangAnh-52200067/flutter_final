import 'package:ecommerce_app/home.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/admin/admin_home_screen.dart';
import 'package:ecommerce_app/screens/auth/forgot_password_screen.dart';
import 'package:ecommerce_app/screens/auth/register_screen.dart';
import 'package:ecommerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecommerce_app/screens/widgets/button_input/input_field.dart';
import 'package:ecommerce_app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = UserRepository();
  bool _obscureTextPassword = true;
  bool _isSigning = false;
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isBackgroundExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isBackgroundExpanded = true;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

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
    bool isBanned = await _userRepository.isUserBannedByEmail(email);

    if (isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tài khoản của bạn đã bị khóa! Vui lòng liên hệ với chúng tôi để biết thêm thông tin",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSigning = false;
      });
      return;
    }
    User? user = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (email == "admin@gmail.com" && password == "admin123") {
      await _auth.setLoggedIn(true);
      await _auth.setUserRole('admin');
      _navigateToScreen(const AdminHomeScreen(), "Đăng nhập Admin thành công!");
      return;
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: height,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bạn chưa có tài khoản?',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(width: 10),
                        CustomButton(
                          text: "Đăng ký",
                          icon: Icons.person_add,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          backgroundColor: Colors.blueAccent,
                          textColor: Colors.white,
                          fontSize: 12,
                          height: 32,
                          width: 120, // Tăng width để chứa icon và text
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    width: width,
                    height: _isBackgroundExpanded ? height / 1.4 : 0,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://res.cloudinary.com/dsj6sba9f/image/upload/v1747506169/c085ad076c442c8191e6b7f48ef59aad_kjevqa.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'T7M SHOP',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Mua sắm - Giá tốt - Mỗi ngày',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
                                      color: Colors.blueAccent,
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
                                  textColor: Colors.white,
                                  icon: Icons.login,
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
                                          builder:
                                              (context) =>
                                                  const ForgotPassword(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Bạn quên mật khẩu?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
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
                                          color: Colors.black87,
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: Text(
                                          'Đăng nhập với',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.black87,
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _SocialButton(
                                      buttonType: ButtonType.facebook,
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 12),
                                    _SocialButton(
                                      buttonType: ButtonType.google,
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 12),
                                    _SocialButton(
                                      buttonType: ButtonType.linkedin,
                                      onTap: () {},
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  final ButtonType buttonType;
  final VoidCallback onTap;

  const _SocialButton({required this.buttonType, required this.onTap});

  @override
  __SocialButtonState createState() => __SocialButtonState();
}

class __SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FlutterSocialButton(
          onTap: () {},
          buttonType: widget.buttonType,
          mini: true,
          iconSize: 15,
        ),
      ),
    );
  }
}
