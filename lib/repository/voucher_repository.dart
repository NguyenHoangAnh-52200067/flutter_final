import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/voucher_model.dart';

class VoucherRepository extends GetxController {
  static VoucherRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  // Thêm voucher mới
  Future<void> addVoucher(VoucherModel voucher) async {
    try {
      await _db.collection("vouchers").doc(voucher.id).set(voucher.toJson());
    } catch (error) {
      throw 'Không thể tạo voucher: $error';
    }
  }

  // Lấy tất cả voucher
  Future<List<VoucherModel>> getAllVouchers() async {
    try {
      final snapshot = await _db.collection("vouchers").get();
      return snapshot.docs
          .map((doc) => VoucherModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (error) {
      throw 'Không thể lấy danh sách voucher: $error';
    }
  }

  // Kiểm tra voucher có tồn tại và hợp lệ
  Future<VoucherModel?> validateVoucher(String code) async {
    try {
      final snapshot =
          await _db
              .collection("vouchers")
              .where('code', isEqualTo: code)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final voucher = VoucherModel.fromJson(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      return voucher.isValid ? voucher : null;
    } catch (error) {
      throw 'Lỗi khi kiểm tra voucher: $error';
    }
  }

  // Cập nhật sau khi sử dụng voucher
  Future<void> updateVoucherUsage(String voucherId, String orderId) async {
    try {
      final docRef = _db.collection("vouchers").doc(voucherId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw 'Voucher không tồn tại';
        }

        final voucher = VoucherModel.fromJson(snapshot.data()!, snapshot.id);
        if (!voucher.isValid) {
          throw 'Voucher đã hết lượt sử dụng';
        }

        transaction.update(docRef, {
          'currentUsage': voucher.currentUsage + 1,
          'usedOrderIds': [...voucher.usedOrderIds, orderId],
        });
      });
    } catch (error) {
      throw 'Không thể cập nhật voucher: $error';
    }
  }

  // Xóa voucher
  Future<void> deleteVoucher(String voucherId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Người dùng chưa đăng nhập.");
      return;
    }
    try {
      await _db.collection("vouchers").doc(voucherId).delete();
    } catch (error) {
      throw 'Không thể xóa voucher: $error';
    }
  }

  // Lấy voucher theo ID
  Future<VoucherModel?> getVoucherById(String voucherId) async {
    try {
      final doc = await _db.collection("vouchers").doc(voucherId).get();
      if (!doc.exists) return null;
      return VoucherModel.fromJson(doc.data()!, doc.id);
    } catch (error) {
      throw 'Không thể lấy thông tin voucher: $error';
    }
  }
}
