import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  final _collection = 'orders';

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
      final querySnapshot = await _db.collection(_collection).get();
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
}
