import 'package:ecomerce_app/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// SCREEN
import 'package:ecomerce_app/screens/auth/login_screen.dart';
import 'package:ecomerce_app/screens/category/category_manage_screen.dart';
import 'package:ecomerce_app/screens/product/product_manage_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProductExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: const Color(0xFF7AE582),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: const Center(
        child: Text(
          "Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF7AE582),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "ICON APP",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.person, "Quản lý người dùng", () {
              // quản lý người dùng
            }),
            _buildDropdownItem(
              icon: Icons.shopping_cart,
              label: "Quản lý sản phẩm",
              isExpanded: _isProductExpanded,
              onTap: () {
                setState(() {
                  _isProductExpanded = !_isProductExpanded;
                });
              },
              children: [
                _buildSubItem("Danh mục", Icons.list, () {
                  Navigator.of(context)
                      .push(_createRoute(const CategoryManagementScreen()));
                }),
                _buildSubItem("Sản phẩm", Icons.shopping_bag, () {
                  Navigator.of(context)
                      .push(_createRoute(const ProductManagementScreen()));
                }),
              ],
            ),
            _buildDrawerItem(Icons.receipt_long, "Quản lý đơn hàng", () {
              // quản lý đơn hàng
            }),
            const Spacer(),
            _buildLogoutItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(icon, color: Colors.green),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            leading: Icon(icon, color: Colors.green),
            title: Text(label, style: const TextStyle(fontSize: 16)),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.green),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildSubItem(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(icon, color: Colors.grey),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Đăng xuất", style: const TextStyle(fontSize: 16)),
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
