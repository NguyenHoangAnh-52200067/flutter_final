import 'package:ecomerce_app/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final UserRepository _userRepo = UserRepository();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isOldPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  bool _isChangingPassword = false;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _changePassword() async {
    setState(() {
      _isChangingPassword = true;
    });

    String oldPassword = _oldPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmNewPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      setState(() => _isChangingPassword = false);
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu mới phải có ít nhất 6 ký tự")),
      );
      setState(() => _isChangingPassword = false);
      return;
    }

    if (newPassword == oldPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mật khẩu mới không được trùng với mật khẩu cũ"),
        ),
      );
      setState(() => _isChangingPassword = false);
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mật khẩu mới không khớp")));
      setState(() => _isChangingPassword = false);
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy tài khoản")),
        );
        setState(() => _isChangingPassword = false);
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!")));

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Lỗi không xác định";

      if (e.code == "wrong-password" || e.code == "invalid-credential") {
        errorMessage = "Mật khẩu cũ không đúng";
      } else if (e.code == "weak-password") {
        errorMessage = "Mật khẩu mới quá yếu";
      } else if (e.code == "requires-recent-login") {
        errorMessage = "Vui lòng đăng nhập lại trước khi đổi mật khẩu";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
    }

    setState(() {
      _isChangingPassword = false;
    });
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscure,
    VoidCallback toggleObscure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isObscure,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleObscure,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: _isEditing,
            readOnly: !_isEditing,
            style: TextStyle(
              color: _isEditing ? Colors.black : Colors.grey.shade700,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 20,
                  color: const Color(0xFF7AE582),
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi mật khẩu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCard("Mật khẩu", [
              _buildPasswordField(
                "Mật khẩu cũ",
                _oldPasswordController,
                _isOldPasswordObscure,
                () {
                  setState(() {
                    _isOldPasswordObscure = !_isOldPasswordObscure;
                  });
                },
              ),
              _buildPasswordField(
                "Mật khẩu mới",
                _newPasswordController,
                _isNewPasswordObscure,
                () {
                  setState(() {
                    _isNewPasswordObscure = !_isNewPasswordObscure;
                  });
                },
              ),
              _buildPasswordField(
                "Nhập lại mật khẩu mới",
                _confirmNewPasswordController,
                _isConfirmPasswordObscure,
                () {
                  setState(() {
                    _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                ),
                child:
                    _isChangingPassword
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Đổi mật khẩu",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
