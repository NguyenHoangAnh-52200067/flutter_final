import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Cài đặt orientation để chỉ portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Scale animation cho nút gửi yêu cầu
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Lắng nghe sự thay đổi trạng thái bàn phím
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Chờ một chút để bàn phím hiện lên
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    // Reset preferred orientations khi widget bị hủy
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Link đặt lại mật khẩu đã được gửi đến email của bạn',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            elevation: 6,
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        default:
          message = e.message ?? 'Đã xảy ra lỗi.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            elevation: 6,
            margin: const EdgeInsets.all(10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery để xác định kích thước màn hình và bàn phím
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Color(0xFF64B5F6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    mediaQuery.size.height -
                    mediaQuery.padding.top -
                    kToolbarHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo và phần tiêu đề sẽ ẩn đi khi bàn phím mở
                    AnimatedOpacity(
                      opacity: isKeyboardOpen ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height:
                            isKeyboardOpen ? 0 : mediaQuery.size.height * 0.2,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'logo',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://res.cloudinary.com/dsj6sba9f/image/upload/v1747506169/c085ad076c442c8191e6b7f48ef59aad_kjevqa.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'QUÊN MẬT KHẨU?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Phần chính - form nhập email
                    SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: isKeyboardOpen ? 10 : 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Thông báo hướng dẫn
                            Container(
                              height: isKeyboardOpen ? 40 : 50,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Đừng lo lắng! Hãy nhập email của bạn đã đăng ký và chúng tôi sẽ gửi link để đặt lại mật khẩu',
                                style: TextStyle(
                                  fontSize: isKeyboardOpen ? 12 : 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Card chứa form
                            Card(
                              elevation: 8,
                              shadowColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Input nhập email
                                      TextFormField(
                                        controller: _emailController,
                                        focusNode: _focusNode,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 15,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blue,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: const BorderSide(
                                                  color: Colors.redAccent,
                                                  width: 2,
                                                ),
                                              ),
                                          hintText: 'Nhập email của bạn',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: Container(
                                            margin: const EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                            ),
                                            child: const Icon(
                                              Icons.email_rounded,
                                              color: Colors.blueAccent,
                                              size: 22,
                                            ),
                                          ),
                                          errorStyle: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập email';
                                          }
                                          final RegExp emailRegExp = RegExp(
                                            r'^[^@]+@[^@]+\.[^@]+$',
                                          );
                                          if (!emailRegExp.hasMatch(value)) {
                                            _focusNode.requestFocus();
                                            return 'Email không đúng định dạng';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      // Nút gửi yêu cầu
                                      ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.blue,
                                                Colors.blueAccent,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading
                                                    ? null
                                                    : _resetPassword,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                            ),
                                            child:
                                                _isLoading
                                                    ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                    )
                                                    : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Text(
                                                          'GỬI YÊU CẦU',
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.arrow_forward,
                                                            size: 16,
                                                            color: Colors.white,
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
                          ],
                        ),
                      ),
                    ),

                    // Bottom spacing to ensure content is visible when keyboard appears
                    SizedBox(height: isKeyboardOpen ? 20 : 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
