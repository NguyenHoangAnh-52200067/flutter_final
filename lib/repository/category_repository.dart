import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/category_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryRepository extends GetxController {
  static CategoryRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  // Thêm danh mục
  Future<void> addCategory(BuildContext context, CategoryModel category) async {
    try {
      DocumentReference docRef = _db.collection("categories").doc();
      category.id = docRef.id;
      await docRef.set(category.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thêm danh mục thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      _handleError(context, error);
    }
  }

  // Lấy danh sách tất cả danh mục cha
  Future<List<CategoryModel>> getParentCategories() async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection("categories")
              .where("parentId", isNull: true)
              .get();
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (error) {
      print("Lỗi khi lấy danh mục cha: $error");
      return [];
    }
  }

  // Lấy danh mục con theo parentId
  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection("categories")
              .where("parentId", isEqualTo: parentId)
              .get();
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (error) {
      print("Lỗi khi lấy danh mục con: $error");
      return [];
    }
  }

  // Future<void> deleteCategory(String categoryId) async {
  //   try {
  //     QuerySnapshot subCategories =
  //         await _db
  //             .collection("categories")
  //             .where("parentId", isEqualTo: categoryId)
  //             .get();
  //     for (var doc in subCategories.docs) {
  //       await _db.collection("categories").doc(doc.id).delete();
  //     }

  //     await _db.collection("categories").doc(categoryId).delete();
  //   } catch (e) {
  //     throw Exception("Lỗi khi xóa danh mục: $e");
  //   }
  // }

  Future<void> deleteCategory(String categoryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    try {
      QuerySnapshot subCategories =
          await _db
              .collection("categories")
              .where("parentId", isEqualTo: categoryId)
              .get();

      for (var doc in subCategories.docs) {
        await _db.collection("categories").doc(doc.id).delete();
      }

      QuerySnapshot products =
          await _db
              .collection("products")
              .where("categoryId", isEqualTo: categoryId)
              .get();

      for (var doc in products.docs) {
        await _db.collection("products").doc(doc.id).delete();
      }

      await _db.collection("categories").doc(categoryId).delete();
    } catch (e) {
      throw Exception("Lỗi khi xóa danh mục: $e");
    }
  }

  Future<void> updateCategory(
    BuildContext context,
    CategoryModel category,
  ) async {
    try {
      await _db
          .collection("categories")
          .doc(category.id)
          .update(category.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Danh mục đã được cập nhật"),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (error) {
      _handleError(context, error);
    }
  }

  // // Lấy danh sách tất cả danh mục
  // Future<List<CategoryModel>> getAllCategories() async {
  //   try {
  //     QuerySnapshot snapshot = await _db.collection("categories").get();
  //     return snapshot.docs.map((doc) {
  //       return CategoryModel.fromJson(
  //         doc.data() as Map<String, dynamic>,
  //         doc.id,
  //       );
  //     }).toList();
  //   } catch (error) {
  //     print("Lỗi khi lấy danh sách danh mục: $error");
  //     return [];
  //   }
  // }

  // // Lấy danh mục theo ID
  // Future<CategoryModel?> getCategoryById(String id) async {
  //   try {
  //     DocumentSnapshot doc = await _db.collection("categories").doc(id).get();
  //     if (doc.exists) {
  //       return CategoryModel.fromJson(
  //         doc.data() as Map<String, dynamic>,
  //         doc.id,
  //       );
  //     }
  //   } catch (error) {
  //     print("Lỗi khi lấy danh mục: $error");
  //   }
  //   return null;
  // }

  void _handleError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã có lỗi xảy ra, vui lòng thử lại!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      QuerySnapshot snapshot = await _db.collection("categories").get();
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (error) {
      print("Lỗi khi lấy danh sách danh mục: $error");
      return [];
    }
  }
}
