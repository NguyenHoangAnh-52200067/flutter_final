import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  static const int limit = 10;

  // Thêm sản phẩm
  Future<void> addProduct(ProductModel product) async {
    try {
      product.id = _db.collection("products").doc().id; // Tạo và gán ID tự động
      await _db.collection("products").doc(product.id).set(product.toJson());
      Get.snackbar(
        "Thành công",
        "Thêm sản phẩm thành công",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  // Xóa sản phẩm theo ID
  Future<void> deleteProduct(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    try {
      QuerySnapshot variantSnapshot =
          await _db
              .collection("products")
              .where("parentId", isEqualTo: id)
              .get();

      for (var doc in variantSnapshot.docs) {
        await _db.collection("products").doc(doc.id).delete();
      }

      await _db.collection("products").doc(id).delete();

      Get.snackbar(
        "Xóa thành công",
        "Sản phẩm đã được xóa",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  // Sửa sản phẩm theo ID
  Future<void> updateProduct(ProductModel product) async {
    try {
      DocumentSnapshot docSnapshot =
          await _db.collection("products").doc(product.id).get();

      if (!docSnapshot.exists) {
        Get.snackbar(
          "Lỗi",
          "Sản phẩm không tồn tại!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Map<String, dynamic> oldData = docSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> updatedData = product.toJson();

      if (updatedData["parentId"] == null && oldData.containsKey("parentId")) {
        updatedData["parentId"] = oldData["parentId"];
      }

      await _db.collection("products").doc(product.id).update(updatedData);
      Get.snackbar(
        "Cập nhật thành công",
        "Sản phẩm đã được cập nhật",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> updateProductStock(String productId, int quantity) async {
    try {
      DocumentSnapshot docSnapshot =
          await _db.collection("products").doc(productId).get();
      print("Sản phẩm tìm được là $productId");
      if (!docSnapshot.exists) {
        Get.snackbar(
          "Lỗi",
          "Sản phẩm không tồn tại!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Map<String, dynamic> oldData = docSnapshot.data() as Map<String, dynamic>;
      print("Dữ liệu sản phẩm: $oldData");

      // Kiểm tra xem 'stock' có tồn tại trong dữ liệu không
      if (!oldData.containsKey('stock')) {
        print("Lỗi: Trường 'stock' không tồn tại trong sản phẩm");
        Get.snackbar(
          "Lỗi",
          "Không thể cập nhật số lượng sản phẩm",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      int currentStock = oldData['stock'] ?? 0;
      print("Số lượng hiện tại: $currentStock, Số lượng cần giảm: $quantity");
      int newStock = currentStock - quantity;
      if (newStock < 0) newStock = 0;
      print("Số lượng mới: $newStock");

      await _db.collection("products").doc(productId).update({
        'stock': newStock,
      });

      // Kiểm tra xác nhận cập nhật đã thành công
      DocumentSnapshot updatedDoc =
          await _db.collection("products").doc(productId).get();
      Map<String, dynamic> updatedData =
          updatedDoc.data() as Map<String, dynamic>;
      print("Số lượng sau khi cập nhật: ${updatedData['stock']}");
    } catch (error) {
      print("Lỗi khi cập nhật số lượng sản phẩm: $error");
      _handleError(error);
    }
  }

  Future<void> undoProductStock(String productId, int quantity) async {
    try {
      DocumentSnapshot docSnapshot =
          await _db.collection("products").doc(productId).get();

      if (!docSnapshot.exists) {
        Get.snackbar(
          "Lỗi",
          "Sản phẩm không tồn tại!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Map<String, dynamic> oldData = docSnapshot.data() as Map<String, dynamic>;
      int currentStock = oldData['stock'] ?? 0;
      int newStock = currentStock + quantity;
      if (newStock < 0) newStock = 0;

      await _db.collection("products").doc(productId).update({
        'stock': newStock,
      });
    } catch (error) {
      _handleError(error);
    }
  }

  // Lấy danh sách tất cả sản phẩm
  Future<List<ProductModel>> getAllProducts() async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection("products")
              .where("parentId", isNull: true)
              .get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (error) {
      print("Lỗi khi lấy danh sách sản phẩm: $error");
      return [];
    }
  }

  // Lấy chi tiết sản phẩm theo ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection("products").doc(id).get();
      if (doc.exists) {
        return ProductModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    } catch (error) {
      print("Lỗi khi lấy sản phẩm: $error");
    }
    return null;
  }

  // Lấy danh sách sản phẩm theo categoryId
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection("products")
              .where("categoryId", isEqualTo: categoryId)
              .get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (error) {
      print("Lỗi khi lấy danh sách sản phẩm theo danh mục: $error");
      return [];
    }
  }

  Future<Map<String, dynamic>> getProductsByCategory2(
    String categoryId, {
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db
        .collection("products")
        .where("categoryId", isEqualTo: categoryId)
        .where("parentId", isNull: true)
        .limit(6);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      return {"products": [], "lastDoc": null};
    }

    List<ProductModel> products =
        snapshot.docs
            .map(
              (doc) => ProductModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

    return {
      "products": products,
      "lastDoc": snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    };
  }

  // Lấy danh sách biến thể của một sản phẩm
  Future<List<ProductModel>> getVariants(String parentId) async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection("products")
              .where("parentId", isEqualTo: parentId)
              .get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (error) {
      print("Lỗi khi lấy biến thể sản phẩm: $error");
      return [];
    }
  }

  Future<void> addVariant(
    ProductModel parentProduct,
    ProductModel variant,
  ) async {
    if (variant.parentId == null) {
      print("Biến thể phải có parentId!");
      return;
    }

    try {
      DocumentReference docRef = await _db
          .collection("products")
          .add(variant.toJson());
      String newVariantId = docRef.id;

      await docRef.update({"id": newVariantId});

      List<String> updatedVariantIds = [
        ...parentProduct.variantIds,
        newVariantId,
      ];

      await _db.collection("products").doc(parentProduct.id).update({
        "variantIds": updatedVariantIds,
      });

      Get.snackbar(
        "Thành công",
        "Thêm biến thể thành công",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  void _handleError(dynamic error) {
    Get.snackbar(
      "Lỗi",
      "Đã có lỗi xảy ra, vui lòng thử lại!",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void updateStock(String s, int i) {}

  Future<void> updateProductRating(String productId, double rating) async {
    try {
      await _db.collection("products").doc(productId).update({
        'rating': rating,
      });
    } catch (error) {
      _handleError(error);
    }
  }
}
