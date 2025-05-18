import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/category_model.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/category_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/cart/voucher_screen.dart';
import 'package:ecommerce_app/screens/chat/chat_screen.dart';
import 'package:ecommerce_app/screens/dashboard/dashboard_product_list_screen.dart';
import 'package:ecommerce_app/screens/widgets/appbar/home_appbar.dart';
import 'package:ecommerce_app/screens/widgets/banner/banner_widget.dart';
import 'package:ecommerce_app/screens/widgets/form/header_container.dart';
import 'package:ecommerce_app/screens/widgets/form/home_category.dart';
import 'package:ecommerce_app/screens/widgets/search/search_container.dart';
import 'package:ecommerce_app/screens/widgets/text/section_heading_1.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final UserRepository _userRepo = UserRepository();
  String _fullName = "Khách hàng";

  // Category
  final CategoryRepository _categoryRepo = CategoryRepository();
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCategories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _isAdmin = _user?.email == 'admin@gmail.com';
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              HeaderContainer(
                child: Column(
                  children: [
                    HomeAppBar(fullName: _fullName),
                    const SizedBox(height: 15),
                    SearchContainer(text: 'Tìm kiếm trong cửa hàng'),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          SectionHeading1(
                            title: 'Danh mục phổ biến',
                            textColor: Colors.white,
                            showActionButton: false,
                          ),
                          HomeCategories(categories: _categories),
                          VoucherWidget(),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                ).copyWith(top: 15, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BannerWidget(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _categories[index].name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 250,
                              child: ProductListView(
                                categoryId: _categories[index].id!,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        floatingActionButton:
            !_isAdmin
                ? FloatingActionButton(
                  onPressed: () async {
                    User? currentUser = FirebaseAuth.instance.currentUser;

                    if (currentUser == null) {
                      print("vô rồi");
                      UserCredential userCredential =
                          await FirebaseAuth.instance.signInAnonymously();
                      print("sao kì z");
                      currentUser = userCredential.user;
                      print("userid: " + currentUser!.uid);
                    }

                    final roomId = '${currentUser?.uid}_admin';
                    print(roomId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(roomId: roomId),
                      ),
                    );
                  },
                  child: Icon(Icons.chat),
                )
                : null,
      ),
    );
  }

  void _loadUser() async {
    if (_user != null) {
      UserModel? userModel = await _userRepo.getUserDetails(_user.uid);
      if (userModel != null) {
        setState(() {
          _fullName = userModel.fullName;
        });
      }
    }
  }

  void _loadCategories() async {
    List<CategoryModel> categories = await _categoryRepo.getParentCategories();
    Map<String, double> categoryMaxPrice = {};

    if (categories.isEmpty) {
      print("Không có danh mục");
      return;
    }

    for (var category in categories) {
      if (category.id == null) {
        continue;
      }

      double maxPrice = await _getMaxPriceInCategory(category.id!);
      categoryMaxPrice[category.id!] = maxPrice;
    }

    categories.sort(
      (a, b) =>
          (categoryMaxPrice[b.id] ?? 0).compareTo(categoryMaxPrice[a.id] ?? 0),
    );

    setState(() {
      _categories = categories;
    });
  }

  Future<double> _getMaxPriceInCategory(String categoryId) async {
    var querySnapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .orderBy('price', descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      return 0;
    }

    double maxPrice = querySnapshot.docs.first['price'].toDouble();
    return maxPrice;
  }
}
