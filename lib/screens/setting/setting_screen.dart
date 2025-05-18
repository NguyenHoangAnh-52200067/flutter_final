import 'package:ecommerce_app/home.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/models/voucher_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/repository/user_voucher_repository.dart';
import 'package:ecommerce_app/repository/voucher_repository.dart';
import 'package:ecommerce_app/screens/admin/admin_home_screen.dart';
import 'package:ecommerce_app/screens/auth/login_screen.dart';
import 'package:ecommerce_app/screens/auth/register_screen.dart';
import 'package:ecommerce_app/screens/cart/address_screen.dart';
import 'package:ecommerce_app/screens/cart/order_screen.dart';
import 'package:ecommerce_app/screens/cart/voucher_list_screen.dart';
import 'package:ecommerce_app/screens/profile/edit_password_screen.dart';
import 'package:ecommerce_app/screens/widgets/appbar/custom_appbar.dart';
import 'package:ecommerce_app/screens/widgets/button_input/custom_button.dart';
import 'package:ecommerce_app/screens/widgets/form/header_container.dart';
import 'package:ecommerce_app/screens/widgets/form/setting_menu_tile.dart';
import 'package:ecommerce_app/screens/widgets/form/user_profile_tile.dart';
import 'package:ecommerce_app/screens/widgets/text/section_heading_1.dart';
import 'package:ecommerce_app/services/firebase_auth_service.dart';
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
  final UserVoucherRepository _userVoucherRepository = UserVoucherRepository();
  final VoucherRepository _voucherRepository = VoucherRepository();

  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _email;
  String? _fullName;
  String? _linkImage;
  int? memberShipCurrentPoint;
  int? memberShipPoint;

  TabController? _tabController;
  List<String> _userVouchers = [];
  List<VoucherModel> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchUserData();
    _fetchUserVouchers();
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

  void _fetchUserVouchers() async {
    try {
      final userId = await _userRepo.getEffectiveUserId();

      final userVoucherList = await _userVoucherRepository.getUserVouchers(
        userId,
      );
      final userVoucherIds =
          userVoucherList
              .where((e) => !e.isUsed)
              .map((e) => e.voucherId)
              .toList();

      final allVouchers = await _voucherRepository.getAllVouchers();

      final userVouchers =
          allVouchers
              .where((voucher) => userVoucherIds.contains(voucher.id))
              .toList();

      if (mounted) {
        setState(() {
          _vouchers = userVouchers;
          _userVouchers = userVoucherIds;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải voucher: $e")));
      }
    }
  }

  void _fetchUserData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      UserModel? userModel = await _userRepo.getUserDetails(user.uid);
      if (userModel != null) {
        _updateUserMemberShipLevel(userModel.id!, userModel.memberShipPoint!);
        setState(() {
          _isAdmin = userModel.email == "admin@gmail.com";
          _email = userModel.email;
          _fullName = userModel.fullName;
          _linkImage = userModel.linkImage;
          memberShipCurrentPoint = userModel.memberShipCurrentPoint;
          memberShipPoint = userModel.memberShipPoint;
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

  void _updateUserMemberShipLevel(String userId, int points) async {
    UserModel? userModel = await _userRepo.getUserDetails(userId);
    try {
      if (userModel != null) {
        if (userModel.memberShipPoint! >= 1000 &&
            userModel.memberShipPoint! < 3000) {
          await _userRepo.updateMembershipLevel(userId, 'Bạc');
          return;
        }
        if (userModel.memberShipPoint! >= 3000 &&
            userModel.memberShipPoint! < 5000) {
          await _userRepo.updateMembershipLevel(userId, 'Vàng');
          return;
        }
        if (userModel.memberShipPoint! >= 5000 &&
            userModel.memberShipPoint! < 10000) {
          await _userRepo.updateMembershipLevel(userId, 'Bạch kim');
          return;
        }
        if (userModel.memberShipPoint! >= 10000) {
          await _userRepo.updateMembershipLevel(userId, 'Kim cương');
          return;
        }
      }

      await _userRepo.updateMembershipLevel(userId, 'Thành viên');
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
                        color: Colors.white,
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

                                      textColor: Colors.white,
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
                                      height: 35,
                                      fontSize: 10,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      text: "Đăng ký",
                                      textColor: Colors.white,
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
                                      height: 35,
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
            if (_isLoggedIn) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điểm tích lũy có thể dùng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 98, 98, 98),
                          ),
                        ),
                        Text(
                          '${memberShipCurrentPoint ?? 0} điểm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Khách hàng thân thiết',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 134, 134, 134),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          memberShipPoint == null || memberShipPoint! < 1000
                              ? 'Thành viên'
                              : memberShipPoint! < 3000
                              ? 'Hạng Bạc'
                              : memberShipPoint! < 5000
                              ? 'Hạng Vàng'
                              : memberShipPoint! < 10000
                              ? 'Hạng Bạch kim'
                              : 'Hạng Kim cương',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                memberShipPoint == null ||
                                        memberShipPoint! < 1000
                                    ? Colors.blue[700]
                                    : memberShipPoint! < 3000
                                    ? Colors.grey[400]
                                    : memberShipPoint! < 5000
                                    ? Colors.amber[600]
                                    : memberShipPoint! < 10000
                                    ? Colors.grey[300]
                                    : Colors.blue,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.grey.withOpacity(0.3),
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 18, right: 18),
              child: Column(
                children: [
                  // Order bar
                  if (_isLoggedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đơn hàng đã mua',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderScreen(),
                              ),
                            );
                          },

                          child: Row(
                            children: [
                              const Text(
                                'Xem tất cả',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const OrderScreen(
                                          initialTabIndex: 1,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 6),
                                    const Center(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Chờ xác nhận',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const OrderScreen(
                                          initialTabIndex: 2,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 6),
                                    const Center(
                                      child: Icon(
                                        Icons.local_shipping_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Chờ giao hàng',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const OrderScreen(
                                          initialTabIndex: 3,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 6),
                                    const Center(
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Đã giao',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                    SizedBox(height: 18),
                    const SectionHeading1(
                      title: 'Tài khoản',
                      textColor: Colors.black,
                      showActionButton: false,
                    ),
                    if (_isAdmin)
                      SettingMenuTile(
                        icon: Icons.home_outlined,
                        title: 'Admin Dashboard',
                        subTitle: 'Quản lý hệ thống',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminHomeScreen(),
                            ),
                          );
                        },
                      ),
                    SettingMenuTile(
                      icon: Icons.home_outlined,
                      title: 'Trang chủ',
                      subTitle: 'Quay về trang chủ',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                    ),
                    SettingMenuTile(
                      icon: Icons.discount_outlined,
                      title: 'Kho Voucher',
                      subTitle: 'Tất cả voucher của bạn',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VoucherListScreen(
                                  vouchers: _vouchers,
                                  showSaveButton: false,
                                ),
                          ),
                        );
                      },
                    ),
                    SettingMenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Địa chỉ',
                      subTitle: 'Cài đặt địa chỉ giao hàng',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressScreen(),
                          ),
                        );
                      },
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
                    textColor: Colors.black,
                    showActionButton: false,
                  ),
                  SettingMenuTile(
                    icon: Icons.home_outlined,
                    title: 'Trang chủ',
                    subTitle: 'Quay về trang chủ',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
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
                      textColor: Colors.black,
                      showActionButton: false,
                    ),
                    SettingMenuTile(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      subTitle: 'Đăng xuất khỏi ứng dụng',
                      onTap: () async {
                        await FirebaseAuthService().signOut();
                        setState(() {
                          _isLoggedIn = false;
                        });
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
