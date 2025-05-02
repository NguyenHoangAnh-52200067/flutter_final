import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_voucher_model.dart';

class UserVoucherRepository extends GetxController {
  static UserVoucherRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _collection = "user_vouchers";

  // Thêm voucher cho user
  Future<void> addUserVoucher(UserVoucherModel userVoucher) async {
    try {
      await _db
          .collection(_collection)
          .doc(userVoucher.id)
          .set(userVoucher.toJson());
    } catch (error) {
      throw 'Không thể lưu voucher: $error';
    }
  }

  // Lấy tất cả voucher của một user
  Future<List<UserVoucherModel>> getUserVouchers(String userId) async {
    try {
      final snapshot =
          await _db
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      return snapshot.docs
          .map((doc) => UserVoucherModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (error) {
      throw 'Không thể lấy danh sách voucher: $error';
    }
  }

  // Lấy voucher cụ thể của user
  Future<UserVoucherModel?> getUserVoucherById(String userVoucherId) async {
    try {
      final doc = await _db.collection(_collection).doc(userVoucherId).get();
      if (!doc.exists) return null;
      return UserVoucherModel.fromJson(doc.data()!, doc.id);
    } catch (error) {
      throw 'Không thể lấy thông tin voucher: $error';
    }
  }

  // Kiểm tra user đã lưu voucher chưa
  Future<bool> hasUserSavedVoucher(String userId, String voucherId) async {
    try {
      final snapshot =
          await _db
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('voucherId', isEqualTo: voucherId)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (error) {
      throw 'Không thể kiểm tra voucher: $error';
    }
  }

  // Cập nhật trạng thái sử dụng voucher
  Future<void> updateVoucherUsageStatus(
    String userId,
    String voucherId,
    bool isUsed,
    String orderId,
  ) async {
    try {
      final querySnapshot =
          await _db
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('voucherId', isEqualTo: voucherId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Không tìm thấy voucher của người dùng';
      }

      final userVoucherId = querySnapshot.docs.first.id;

      await _db.collection(_collection).doc(userVoucherId).update({
        'isUsed': isUsed,
        'orderId': orderId,
      });
    } catch (error) {
      throw 'Không thể cập nhật trạng thái voucher: $error';
    }
  }

  // Xóa voucher của user
  Future<void> deleteUserVoucher(String userVoucherId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Người dùng chưa đăng nhập';
    }

    try {
      await _db.collection(_collection).doc(userVoucherId).delete();
    } catch (error) {
      throw 'Không thể xóa voucher: $error';
    }
  }

  // Lấy các voucher chưa sử dụng của user
  Future<List<UserVoucherModel>> getUnusedUserVouchers(String userId) async {
    try {
      final snapshot =
          await _db
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('isUsed', isEqualTo: false)
              .get();

      return snapshot.docs
          .map((doc) => UserVoucherModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (error) {
      throw 'Không thể lấy danh sách voucher chưa sử dụng: $error';
    }
  }

  // Lấy các voucher đã sử dụng của user
  Future<List<UserVoucherModel>> getUsedUserVouchers(String userId) async {
    try {
      final snapshot =
          await _db
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('isUsed', isEqualTo: true)
              .get();

      return snapshot.docs
          .map((doc) => UserVoucherModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (error) {
      throw 'Không thể lấy danh sách voucher đã sử dụng: $error';
    }
  }
}
