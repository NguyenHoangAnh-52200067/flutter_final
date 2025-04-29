import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecomerce_app/models/cart_model.dart';
import 'package:ecomerce_app/models/cartitems_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CartRepository extends GetxController {
  final _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  // Thêm sản phẩm vào giỏ hàng
  Future<void> addItem(Cart cart, CartItem newItem) async {
    try {
      final cartRef = _db.collection('carts').doc(cart.userId);
      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Kiểm tra sản phẩm đã tồn tại
        final existingItems = List<CartItem>.from(
          (cartDoc.data()?['items'] as List).map(
            (item) => CartItem.fromMap(item),
          ),
        );

        final existingItemIndex = existingItems.indexWhere(
          (item) =>
              item.productId == newItem.productId &&
              item.variantName == newItem.variantName,
        );

        if (existingItemIndex >= 0) {
          // Cập nhật số lượng nếu sản phẩm đã tồn tại
          existingItems[existingItemIndex].quantity += newItem.quantity;
          await cartRef.update({
            'items': existingItems.map((item) => item.toMap()).toList(),
          });
        } else {
          // Thêm sản phẩm mới
          await cartRef.update({
            'items': FieldValue.arrayUnion([newItem.toMap()]),
          });
        }
      } else {
        // Tạo giỏ hàng mới
        await cartRef.set({
          'userId': cart.userId,
          'items': [newItem.toMap()],
          'cartId': _db.collection('carts').doc().id,
        });
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  // Cập nhật số lượng của một item trong giỏ hàng
  Future<void> updateItemQuantity(
    Cart cart,
    String itemId,
    int newQuantity,
  ) async {
    try {
      if (newQuantity <= 0) {
        throw Exception('Quantity must be greater than 0');
      }

      final cartRef = _db.collection('carts').doc(cart.userId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        throw Exception('Cart not found');
      }

      final items = List<CartItem>.from(
        (cartDoc.data()?['items'] as List).map(
          (item) => CartItem.fromMap(item),
        ),
      );

      final itemIndex = items.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        throw Exception('Item not found in cart');
      }

      items[itemIndex].quantity = newQuantity;
      await cartRef.update({
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Error updating item quantity: $e');
      throw Exception('Failed to update item quantity: $e');
    }
  }

  Future<void> removeSelectedItems(String userId, List<String> itemIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (itemIds.isEmpty) {
      throw Exception('No items selected');
    }
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    try {
      final cartRef = _db.collection('carts').doc(userId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        throw Exception('Cart not found');
      }

      final items = List<CartItem>.from(
        (cartDoc.data()?['items'] as List).map(
          (item) => CartItem.fromMap(item),
        ),
      );

      items.removeWhere((item) => itemIds.contains(item.id));

      await cartRef.update({
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Error removing selected items from cart: $e');
      throw Exception('Failed to remove selected items from cart: $e');
    }
  }

  // Xóa một item khỏi giỏ hàng
  Future<void> removeItem(Cart cart, String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    try {
      final cartRef = _db.collection('carts').doc(cart.userId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        throw Exception('Cart not found');
      }

      final items = List<CartItem>.from(
        (cartDoc.data()?['items'] as List).map(
          (item) => CartItem.fromMap(item),
        ),
      );

      final initialLength = items.length;
      items.removeWhere((item) => item.id == itemId);

      if (items.length == initialLength) {
        throw Exception('Item not found in cart');
      }

      await cartRef.update({
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Error removing item from cart: $e');
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<void> removeGuestCartItem(String guestId, String itemId) async {
    try {
      // Lấy cart document theo guestId
      final cartRef = _db.collection('carts').doc(guestId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        throw Exception('Giỏ hàng không tồn tại');
      }

      // Lấy danh sách các mặt hàng trong giỏ
      final items = List<CartItem>.from(
        (cartDoc.data()?['items'] as List).map(
          (item) => CartItem.fromMap(item),
        ),
      );

      // Xử lý xóa mục trong giỏ
      final initialLength = items.length;
      items.removeWhere((item) => item.id == itemId);

      if (items.length == initialLength) {
        throw Exception('Không tìm thấy item trong giỏ hàng');
      }

      // Cập nhật lại giỏ hàng
      await cartRef.update({
        'items': items.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Lỗi khi xóa item khỏi giỏ hàng: $e');
      throw Exception('Không thể xóa item khỏi giỏ hàng: $e');
    }
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart(Cart cart) async {
    try {
      final cartRef = _db.collection('carts').doc(cart.userId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        throw Exception('Cart not found');
      }

      await cartRef.update({'items': []});
    } catch (e) {
      print('Error clearing cart: $e');
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Lưu giỏ hàng vào Firebase
  Future<void> saveCart(Cart cart) async {
    try {
      if (cart.userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      await _db.collection('carts').doc(cart.userId).set(cart.toMap());
    } catch (e) {
      print('Error saving cart: $e');
      throw Exception('Failed to save cart: $e');
    }
  }

  // Lấy giỏ hàng từ Firebase
  Future<Cart> getCart(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final cartDoc = await _db.collection('carts').doc(userId).get();

      if (cartDoc.exists && cartDoc.data() != null) {
        return Cart.fromMap(cartDoc.data()!);
      }

      // Tạo giỏ hàng mới nếu chưa tồn tại
      final newCart = Cart(
        userId: userId,
        cartId: _db.collection('carts').doc().id, // Tạo ID riêng cho cart
        items: [],
      );
      await saveCart(newCart);
      return newCart;
    } catch (e) {
      print('Error loading cart: $e');
      throw Exception('Failed to load cart: $e');
    }
  }

  Future<void> deleteCart(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final cartRef = _db.collection('carts').doc(userId);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        return;
      }

      await cartRef.delete();
    } catch (e) {
      print('Error deleting cart: $e');
      throw Exception('Không thể xóa giỏ hàng: $e');
    }
  }
}
