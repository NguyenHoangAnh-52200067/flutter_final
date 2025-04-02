import 'package:ecomerce_app/home.dart';
import 'package:ecomerce_app/models/user_model.dart';
import 'package:ecomerce_app/repository/user_repository.dart';
import 'package:ecomerce_app/screens/auth/login_screen.dart';
import 'package:ecomerce_app/screens/auth/register_screen.dart';
import 'package:ecomerce_app/screens/profile/edit_password_screen.dart';
import 'package:ecomerce_app/screens/widgets/appbar/custom_appbar.dart';
import 'package:ecomerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecomerce_app/screens/widgets/form/header_container.dart';
import 'package:ecomerce_app/screens/widgets/form/setting_menu_tile.dart';
import 'package:ecomerce_app/screens/widgets/form/user_profile_tile.dart';
import 'package:ecomerce_app/screens/widgets/text/section_heading_1.dart';
import 'package:ecomerce_app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserRepository _userRepo = UserRepository();

  bool _isLoggedIn = false;
  String? _email;
  String? _fullName;
  String? _linkImage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchUserData();
  }

  void _checkLoginStatus() async {
    bool isLoggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      _fetchUserData();
    }
  }

  void _fetchUserData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      UserModel? userModel = await _userRepo.getUserDetails(user.uid);
      if (userModel != null) {
        setState(() {
          _email = userModel.email;
          _fullName = userModel.fullName;
          _linkImage = userModel.linkImage;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy dữ liệu người dùng")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            HeaderContainer(
              child: Column(
                children: [
                  // AppBar
                  CustomAppBar(
                    title: Text(
                      'Cài đặt',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions:
                        _isLoggedIn
                            ? []
                            : [
                              SizedBox(
                                width: 250,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButton(
                                      text: "Đăng nhập",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const LoginScreen(),
                                          ),
                                        );
                                      },
                                      width: 98,
                                      height: 25,
                                      fontSize: 10,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      text: "Đăng ký",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const SignUpScreen(),
                                          ),
                                        );
                                      },
                                      width: 98,
                                      height: 25,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                  ),
                  if (_isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: UserProfileTile(
                        fullName: _fullName ?? 'Người dùng',
                        email: _email ?? 'abc@gmail.com',
                        linkImage: _linkImage,
                      ),
                    ),
                  const SizedBox(height: 36),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  if (_isLoggedIn) ...[
                    const SectionHeading1(
                      title: 'Tài khoản',
                      showActionButton: false,
                    ),
                    SettingMenuTile(
                      icon: Icons.home,
                      title: 'Địa chỉ',
                      subTitle: 'Cài đặt địa chỉ',
                      onTap: () {},
                    ),
                    SettingMenuTile(
                      icon: Icons.password,
                      title: 'Mật khẩu',
                      subTitle: 'Đổi mật khẩu',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditPasswordScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SectionHeading1(
                    title: 'Nâng cao',
                    showActionButton: false,
                  ),
                  SettingMenuTile(
                    icon: Icons.language,
                    title: 'Ngôn ngữ',
                    subTitle: 'Chọn ngôn ngữ',
                    onTap: () {},
                  ),
                  SettingMenuTile(
                    icon: Icons.notifications,
                    title: 'Thông báo',
                    subTitle: 'Cài đặt thông báo',
                    onTap: () {},
                  ),
                  SettingMenuTile(
                    icon: Icons.brightness_6,
                    title: 'Chế độ tối',
                    subTitle: 'Thay đổi hiển thị nền',
                    trailing: GFToggle(
                      onChanged: (val) {},
                      value: false,
                      enabledTrackColor: Colors.blue,
                      enabledThumbColor: Colors.white,
                      type: GFToggleType.ios,
                    ),
                  ),
                  SettingMenuTile(
                    icon: Icons.help,
                    title: 'Hỗ trợ',
                    subTitle: 'Gửi hỗ trợ',
                    onTap: () {},
                  ),

                  if (_isLoggedIn) ...[
                    const SizedBox(height: 12),
                    const SectionHeading1(
                      title: 'Khác',
                      showActionButton: false,
                    ),
                    SettingMenuTile(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      subTitle: 'Đăng xuất khỏi ứng dụng',
                      onTap: () async {
                        await FirebaseAuthService().signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
