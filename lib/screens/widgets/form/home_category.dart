import 'package:ecomerce_app/models/category_model.dart';
import 'package:ecomerce_app/screens/widgets/grid/category_products_grid.dart';
import 'package:ecomerce_app/screens/widgets/image_text_widget/vertical_image_text.dart';
import 'package:ecomerce_app/utils/image_utils.dart';
import 'package:flutter/material.dart';

class HomeCategories extends StatelessWidget {
  final List<CategoryModel> categories;

  const HomeCategories({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: categories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = categories[index];
          return VerticalImageText(
            image: Image.network(category.imageUrl!, width: 30, height: 30),
            title: category.name,
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
          );
        },
      ),
    );
  }
}
