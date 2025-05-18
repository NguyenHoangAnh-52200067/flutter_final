import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/mail_service.dart';
import '../utils/utils.dart';
import '../repository/user_repository.dart';

class OrderRepository {
  final _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final _collection = 'orders';
  final _mailService = MailService();
  final _userRepository = UserRepository();

  Future<String> addOrder(OrderModel order) async {
    await _db.collection(_collection).doc(order.id).set(order.toJson());
    return order.id;
  }

  Future<void> deleteOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    await _db.collection(_collection).doc(orderId).delete();
  }

  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (doc.exists) {
      return OrderModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection(_collection).doc(orderId).update({'status': status});
  }

  Future<void> updateAcceptDate(String orderId) async {
    await _db.collection(_collection).doc(orderId).update({
      'acceptDate': DateTime.now(),
    });
  }

  Future<void> updateShippingDate(String orderId) async {
    await _db.collection(_collection).doc(orderId).update({
      'shippingDate': DateTime.now(),
    });
  }

  Future<void> updatePaymentDate(String orderId) async {
    await _db.collection(_collection).doc(orderId).update({
      'paymentDate': DateTime.now(),
    });
  }

  Future<void> updateDeliveryDate(String orderId) async {
    await _db.collection(_collection).doc(orderId).update({
      'deliveryDate': DateTime.now(),
    });
  }

  Future<void> updateVoucherCode(String orderId, String voucherId) async {
    await _db.collection(_collection).doc(orderId).update({
      'voucherCode': voucherId,
    });
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      print("trong hàm getAllOrders");
      final querySnapshot = await _db.collection(_collection).get();
      print("sau hàm getallorders");
      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting all orders: $e');
    }
  }

  Future<void> updateConversionPoint(String orderId, double points) async {
    await _db.collection(_collection).doc(orderId).update({
      'conversionPoint': points,
    });
  }

  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    final snapshot =
        await _db
            .collection(_collection)
            .where('customerId', isEqualTo: userId)
            .get();
    return snapshot.docs
        .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // New methods from OrderController

  // Mark order as delivered and handle all related operations
  Future<void> markOrderAsDelivered(String orderId) async {
    try {
      // Update order status
      await updateOrderStatus(orderId, 'Đã giao');

      // Update delivery date
      await updateDeliveryDate(orderId);

      // Update payment date if needed
      await updatePaymentDate(orderId);

      // Get order details
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Calculate points earned
      final pointsEarned = calculatePointsEarned(order.totalAmount);

      // Update conversion points in the order
      await updateConversionPoint(orderId, pointsEarned);

      // Send delivery confirmation email
      if (order.customerEmail.isNotEmpty) {
        // Fetch products for the email
        final products = await _fetchOrderProducts(order);

        await _mailService.sendOrderDeliveredEmail(
          order.customerEmail,
          order.customerName,
          order.id,
          Utils.formatCurrency(order.totalAmount),
          products,
          order.shippingFee,
          pointsEarned,
        );
      }

      // Update user points
      await _userRepository.updateMembershipPoints(
        order.customerId,
        pointsEarned.toInt(),
      );

      await _userRepository.addMembershipCurrentPoints(
        order.customerId,
        pointsEarned.toInt(),
      );
    } catch (e) {
      print('Error marking order as delivered: $e');
      throw Exception('Failed to mark order as delivered: $e');
    }
  }

  // Calculate points earned from order total
  double calculatePointsEarned(double total) {
    // 1 point for every 10,000 VND
    return (total / 10000).floor().toDouble();
  }

  // Helper method to fetch products for an order
  Future<List<ProductModel>> _fetchOrderProducts(OrderModel order) async {
    final List<ProductModel> products = [];
    final productRepository = ProductRepository();

    for (var detail in order.orderDetails) {
      final product = await productRepository.getProductById(
        detail.product.id!,
      );
      if (product != null) {
        products.add(product);
      }
    }

    return products;
  }

  // Mark order as accepted and handle all related operations
  Future<void> markOrderAsAccepted(String orderId) async {
    try {
      // Update order status
      await updateOrderStatus(orderId, 'Chờ giao hàng');

      // Update accept date
      await updateAcceptDate(orderId);

      // Update shipping date
      await updateShippingDate(orderId);

      // Get order details for notification if needed
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Additional logic for order acceptance can be added here
    } catch (e) {
      print('Error marking order as accepted: $e');
      throw Exception('Failed to mark order as accepted: $e');
    }
  }

  // Mark order as canceled
  Future<void> markOrderAsCanceled(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'Đã hủy');
    } catch (e) {
      print('Error marking order as canceled: $e');
      throw Exception('Failed to mark order as canceled: $e');
    }
  }

  // Mark order as returned
  Future<void> markOrderAsReturned(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'Trả hàng');

      // Additional logic for order returns can be added here
    } catch (e) {
      print('Error marking order as returned: $e');
      throw Exception('Failed to mark order as returned: $e');
    }
  }
}
