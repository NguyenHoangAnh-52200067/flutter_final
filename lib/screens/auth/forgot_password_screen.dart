import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// SCREEN
import 'package:ecomerce_app/screens/auth/verifiy_otp_screen.dart';


class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSigning = false;
  final FocusNode _focusNode = FocusNode();

  Future<void> _forgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSigning = true);

      try {
        String email = _emailController.text.trim();

        final response = await http.post(
          Uri.parse(
              "http://127.0.0.1:5001/ecommerce-app-d91e7/us-central1/sendOtpEmail"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email}),
        );

        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");

        final responseData = jsonDecode(response.body);

        setState(() => _isSigning = false);

        if (response.statusCode == 200 && responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ??
                    'OTP đã được gửi tới email của bạn!')),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('otp', responseData['otp'] ?? '');
          await prefs.setInt('otp_time', DateTime.now().millisecondsSinceEpoch);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerifyOTP(email: email)),
          );
        } else {
          _showErrorMessage(responseData['message'] ?? 'Gửi OTP thất bại');
        }
      } catch (e) {
        setState(() => _isSigning = false);
        _showErrorMessage('Lỗi: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Color(0xFF7AE582),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 30),
                const Text(
                  'QUÊN MẬT KHẨU?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: const Text(
                    'Đừng lo lắng! Hãy nhập email của bạn đã đăng ký và chúng tôi sẽ gửi cho bạn mã để lấy lại mật khẩu',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.deepPurple),
                            ),
                            hintText: 'Email',
                            fillColor: Colors.grey[200],
                            filled: true,
                          ),
                          validator: (String? value) {
                            final RegExp emailRegExp =
                                RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!emailRegExp.hasMatch(value ?? '')) {
                              _focusNode.requestFocus();
                              return 'Email không đúng định dạng';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ElevatedButton(
                          onPressed:
                              (_emailController.text.isEmpty || _isSigning)
                                  ? null
                                  : _forgotPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _isSigning
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'GỬI YÊU CẦU',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                    ],
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
