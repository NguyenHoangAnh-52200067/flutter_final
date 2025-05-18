import 'package:ecommerce_app/home.dart';
import 'package:ecommerce_app/screens/admin/admin_order_management_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_user_management_screen.dart';
import 'package:ecommerce_app/screens/admin/widgets/admin_chats.dart';
import 'package:ecommerce_app/screens/admin/widgets/advanced_dashboard.dart';
import 'package:ecommerce_app/screens/category/category_manage_screen.dart';
import 'package:ecommerce_app/screens/chat/chat_screen.dart';
import 'package:ecommerce_app/screens/product/product_manage_screen.dart';
import 'package:ecommerce_app/services/firebase_auth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// SCREEN

import 'admin_voucher_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProductExpanded = false;

  int totalUsers = 0;
  int newUsers = 0;
  int totalOrders = 0;
  double totalRevenue = 0;
  double totalProfit = 0;
  List<Map<String, dynamic>> bestSellingProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final newUsersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('createdAt', isGreaterThan: lastMonth)
            .get();

    final ordersSnapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'Đã giao')
            .get();

    final productsMap = <String, int>{};
    double calculatedRevenue = 0;
    double calculatedProfit = 0;

    for (var order in ordersSnapshot.docs) {
      final orderData = order.data();
      final totalAmount = (orderData['totalAmount'] as num).toDouble();
      final revenue = (orderData['revenue'] as num).toDouble();

      calculatedRevenue += totalAmount;
      calculatedProfit += revenue;

      final items = orderData['orderDetails'] as List<dynamic>;
      for (var item in items) {
        final productId = item['product']['id'] as String;
        final quantity = item['quantity'] as int;
        productsMap[productId] = (productsMap[productId] ?? 0) + quantity;
      }
    }

    final sortedEntries =
        productsMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = await Future.wait(
      sortedEntries.take(5).map((entry) async {
        final productDoc =
            await FirebaseFirestore.instance
                .collection('products')
                .doc(entry.key)
                .get();
        return {
          'name': productDoc.data()?['productName'] ?? 'Unknown',
          'quantity': entry.value,
        };
      }),
    );

    setState(() {
      totalUsers = usersSnapshot.size;
      newUsers = newUsersSnapshot.size;
      totalOrders = ordersSnapshot.size;
      totalRevenue = calculatedRevenue;
      totalProfit = calculatedProfit;
      bestSellingProducts = topProducts.cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetricsGrid(),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: constraints.maxHeight * 0.4,
                          child: _buildBestSellingProducts(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildMetricCard(
          'Tổng người dùng',
          totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildMetricCard(
          'Sản phẩm bán chạy',
          bestSellingProducts.isNotEmpty
              ? bestSellingProducts[0]['name']
                  .toString()
                  .split(' ')
                  .take(3)
                  .join(' ')
              : 'N/A',
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricCard(
          'Tổng đơn hàng',
          totalOrders.toString(),
          Icons.shopping_cart,
          Colors.orange,
        ),

        _buildMetricCard(
          'Lợi nhuận',
          currencyFormat.format(totalProfit),
          Icons.trending_up,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 29),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sản phẩm bán chạy',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  bestSellingProducts.isEmpty
                      ? 100
                      : (bestSellingProducts
                              .map((p) => p['quantity'] as int)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= bestSellingProducts.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          bestSellingProducts[value.toInt()]['name']
                              .toString()
                              .split(' ')
                              .take(2)
                              .join('\n'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups:
                  bestSellingProducts
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value['quantity'].toDouble(),
                              color: Colors.blue,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, color: Colors.blueAccent),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              color: Colors.blueAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "T7M SHOP",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
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
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, "Trang chủ", () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }),
            _buildDrawerItem(Icons.person, "Quản lý người dùng", () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminUserManagementScreen(),
                ),
              );
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
                  Navigator.of(
                    context,
                  ).push(_createRoute(const CategoryManagementScreen()));
                }),
                _buildSubItem("Sản phẩm", Icons.shopping_bag, () {
                  Navigator.of(
                    context,
                  ).push(_createRoute(const ProductManagementScreen()));
                }),
              ],
            ),
            _buildDrawerItem(Icons.receipt_long, "Quản lý đơn hàng", () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminOrderManagementScreen(),
                ),
              );
            }),
            _buildDrawerItem(Icons.card_giftcard, "Quản lý Voucher", () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminVoucherManagementScreen(),
                ),
              );
            }),
            _buildDrawerItem(
              Icons.dashboard,
              "Thống kê chi tiết doanh thu",
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdvancedDashboard(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              Icons.support_agent_outlined,
              "Hỗ trợ khách hàng",
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AdminInboxScreen()),
                );
              },
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: Colors.blue),
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
            leading: Icon(icon, color: Colors.blue),
            title: Text(label, style: const TextStyle(fontSize: 16)),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.blue,
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Đăng xuất", style: const TextStyle(fontSize: 16)),
        onTap: () async {
          await FirebaseAuthService().signOut();
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
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
