// import 'package:ecommerce_app/repository/user_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class EditPasswordScreen extends StatefulWidget {
//   const EditPasswordScreen({super.key});

//   @override
//   State<EditPasswordScreen> createState() => _EditPasswordScreenState();
// }

// class _EditPasswordScreenState extends State<EditPasswordScreen> {
//   final User? user = FirebaseAuth.instance.currentUser;
//   final UserRepository _userRepo = UserRepository();

//   final _currentPasswordController = TextEditingController();
//   final _newPasswordController = TextEditingController();
//   final _confirmNewPasswordController = TextEditingController();

//   bool _isCurrentPasswordObscure = true;
//   bool _isNewPasswordObscure = true;
//   bool _isConfirmPasswordObscure = true;

//   bool _isLoading = false;

//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> _changePassword() async {
//     setState(() => _isLoading = true);

//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Xác thực lại với mật khẩu cũ
//         AuthCredential credential = EmailAuthProvider.credential(
//           email: user.email!,
//           password: _currentPasswordController.text,
//         );

//         await user.reauthenticateWithCredential(credential);

//         // Đổi mật khẩu mới
//         await user.updatePassword(_newPasswordController.text);

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Đổi mật khẩu thành công')),
//           );
//           Navigator.pop(context);
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'wrong-password':
//           message = 'Mật khẩu hiện tại không đúng.';
//           break;
//         case 'weak-password':
//           message = 'Mật khẩu mới quá yếu.';
//           break;
//         default:
//           message = e.message ?? 'Đã xảy ra lỗi.';
//       }
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(message)));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Widget _buildPasswordField(
//     String label,
//     TextEditingController controller,
//     bool isObscure,
//     VoidCallback toggleObscure,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 5),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
//           ),
//           child: TextFormField(
//             controller: controller,
//             obscureText: isObscure,
//             decoration: InputDecoration(
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 10,
//               ),
//               border: InputBorder.none,
//               suffixIcon: IconButton(
//                 icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
//                 onPressed: toggleObscure,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//       ],
//     );
//   }

//   Widget _buildLabeledTextField(
//     String label,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 5),
//         Container(
//           decoration: BoxDecoration(
//             color: _isEditing ? Colors.white : Colors.grey.shade200,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             enabled: _isEditing,
//             readOnly: !_isEditing,
//             style: TextStyle(
//               color: _isEditing ? Colors.black : Colors.grey.shade700,
//             ),
//             decoration: const InputDecoration(
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 10,
//               ),
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//       ],
//     );
//   }

//   Widget _buildCard(String title, List<Widget> children) {
//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 3,
//       margin: const EdgeInsets.only(bottom: 15),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 5,
//                   height: 20,
//                   color: const Color(0xFF7AE582),
//                   margin: const EdgeInsets.only(right: 10),
//                 ),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Đổi mật khẩu")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             _buildCard("Mật khẩu", [
//               _buildPasswordField(
//                 "Mật khẩu hiện tại",
//                 _currentPasswordController,
//                 _isCurrentPasswordObscure,
//                 () {
//                   setState(() {
//                     _isCurrentPasswordObscure = !_isCurrentPasswordObscure;
//                   });
//                 },
//               ),
//               _buildPasswordField(
//                 "Mật khẩu mới",
//                 _newPasswordController,
//                 _isNewPasswordObscure,
//                 () {
//                   setState(() {
//                     _isNewPasswordObscure = !_isNewPasswordObscure;
//                   });
//                 },
//               ),
//               _buildPasswordField(
//                 "Nhập lại mật khẩu mới",
//                 _confirmNewPasswordController,
//                 _isConfirmPasswordObscure,
//                 () {
//                   setState(() {
//                     _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _changePassword,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 12,
//                     horizontal: 20,
//                   ),
//                 ),
//                 child:
//                     _isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                           "Đổi mật khẩu",
//                           style: TextStyle(fontSize: 16, color: Colors.white),
//                         ),
//               ),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final UserRepository _userRepo = UserRepository();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isCurrentPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  bool _isLoading = false;

  bool _isEditing = false;

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

    // Fade animation cho toàn bộ giao diện
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Scale animation cho nút
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

    // Slide animation cho card
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Xác thực lại với mật khẩu cũ
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Đổi mật khẩu mới
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đổi mật khẩu thành công')),
          );
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Mật khẩu hiện tại không đúng.';
          break;
        case 'weak-password':
          message = 'Mật khẩu mới quá yếu.';
          break;
        default:
          message = e.message ?? 'Đã xảy ra lỗi.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
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
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 16),
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
          "Đổi Mật Khẩu",
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
                const SizedBox(height: 16),
                _buildCard("Đổi Mật Khẩu", [
                  _buildPasswordField(
                    "Mật Khẩu Hiện Tại",
                    _currentPasswordController,
                    _isCurrentPasswordObscure,
                    () {
                      setState(() {
                        _isCurrentPasswordObscure = !_isCurrentPasswordObscure;
                      });
                    },
                  ),
                  _buildPasswordField(
                    "Mật Khẩu Mới",
                    _newPasswordController,
                    _isNewPasswordObscure,
                    () {
                      setState(() {
                        _isNewPasswordObscure = !_isNewPasswordObscure;
                      });
                    },
                  ),
                  _buildPasswordField(
                    "Nhập Lại Mật Khẩu Mới",
                    _confirmNewPasswordController,
                    _isConfirmPasswordObscure,
                    () {
                      setState(() {
                        _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _changePassword,
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
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              )
                            : const Text(
                                "Đổi Mật Khẩu",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}