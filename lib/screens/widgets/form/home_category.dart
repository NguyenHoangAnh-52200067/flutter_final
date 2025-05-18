import 'package:ecommerce_app/models/category_model.dart';
import 'package:ecommerce_app/screens/widgets/grid/category_products_grid.dart';
import 'package:ecommerce_app/screens/widgets/image_text_widget/vertical_image_text.dart';
import 'package:flutter/material.dart';

class HomeCategories extends StatefulWidget {
  final List<CategoryModel> categories;

  const HomeCategories({super.key, required this.categories});

  @override
  State<HomeCategories> createState() => _HomeCategoriesState();
}

class _HomeCategoriesState extends State<HomeCategories>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.categories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = widget.categories[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: VerticalImageText(
                image: Image.network(
                  category.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: category.name,
                textColor: Colors.blue,
                backgroundColor: Colors.white, // Nền trắng
                border: Border.all(
                  color: Colors.blue.shade300,
                ), // Viền xanh nhạt
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CategoryProductsGrid(
                            categoryId: category.id!,
                            crossAxisCount: 2,
                            padding: const EdgeInsets.all(8),
                            scrollController: ScrollController(),
                            categoryName: category.name,
                          ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
