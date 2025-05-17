import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/guest_user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid uuid = Uuid();
  bool isUserId(String id) {
    final uuidV4Regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );

    return !uuidV4Regex.hasMatch(id);
  }

  String? getCurrentUserId() {
    User? user = _auth.currentUser;
    return user?.uid;
  }

  Future<String> getEffectiveUserId() async {
    final uid = getCurrentUserId();
    if (uid != null) return uid;

    return await GuestUserRepository.getOrCreateGuestId();
  }

  Future<String?> getUserRole(String? userId) async {
    try {
      // Check if userId is null or empty
      if (userId == null || userId.isEmpty) {
        print("getUserRole called with null or empty userId");
        return null;
      }

      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      return userDoc.data()?['role'] ?? 'user';
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  Future<bool> banUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'isBanned': true});
      return true;
    } catch (e) {
      print("Lỗi khi cấm người dùng: ${e.toString()}");
      return false;
    }
  }

  Future<bool> isUserBannedByEmail(String email) async {
    try {
      final querySnapshot =
          await _db.collection('users').where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      return querySnapshot.docs.first.data()['isBanned'] ?? false;
    } catch (e) {
      print("Lỗi kiểm tra trạng thái cấm theo email: $e");
      return false;
    }
  }

  Future<bool> unbanUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'isBanned': false});
      print("Mở khóa Thành công ");
      return true;
    } catch (e) {
      print("Lỗi khi bỏ cấm người dùng: ${e.toString()}");
      return false;
    }
  }

  Future<bool> isUserBanned(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      return userDoc.data()?['isBanned'] ?? false;
    } catch (e) {
      print("Lỗi kiểm tra trạng thái cấm: $e");
      return false;
    }
  }

  Future<void> createUser(BuildContext context, UserModel user) async {
    try {
      await _db.collection("users").doc(user.id).set(user.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Tạo tài khoản thành công"),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (error) {
      print("Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi tạo tài khoản: $error"),
          duration: const Duration(seconds: 100),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<UserModel?> getUserDetails(String id) async {
    final snapshot =
        await _db.collection("users").where("id", isEqualTo: id).get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();

      if (data.isNotEmpty) {
        for (var doc in snapshot.docs) {
          print(doc.data());
        }

        return UserModel(
          id: data["id"] ?? "",
          email: data["email"] ?? "",
          fullName: data["fullName"] ?? "",
          address: data["address"] ?? "",
          linkImage: data["imageLink"] ?? "",

          memberShipPoint: data["membershipPoints"] ?? 0,
          memberShipCurrentPoint: data["memberShipCurrentPoint"] ?? 0,
          memberShipLevel: data["memberShipLevel"] ?? "Thành viên",
        );
      } else {
        print("Dữ liệu người dùng rỗng hoặc không tồn tại");
        return null;
      }
    } else {
      print("Không tìm thấy tài liệu người dùng với ID: $id");
      return null;
    }
  }

  Future<AddressModel?> addAddressToList(
    String userId,
    AddressModel newAddress,
  ) async {
    try {
      final userDoc = _db.collection('users').doc(userId);
      final snapshot = await userDoc.get();
      List<dynamic> currentAddresses = snapshot.data()?['addresses'] ?? [];
      currentAddresses.add(newAddress.toJson());
      await userDoc.update({'addresses': currentAddresses});
      return newAddress;
    } catch (e) {
      print("Lỗi thêm địa chỉ: ${e.toString()}");
      return null;
    }
  }

  Future<String?> updateUser(String userId, UserModel user) async {
    try {
      await _db.collection('users').doc(userId).update(user.toJson());
      return null;
    } catch (e) {
      return "Lỗi cập nhật thông tin: ${e.toString()}";
    }
  }

  Future<void> updatePassword(String newPassword, String email) async {
    try {
      // Kiểm tra xem email có tồn tại không
      var methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw Exception("Không tìm thấy người dùng với email này");
      }

      // Gửi email reset password
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Lỗi cập nhật mật khẩu: ${e.toString()}");
      throw e;
    }
  }

  Future<String?> updateMembershipPoints(
    String userId,
    int additionalPoints,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return "Không tìm thấy người dùng";
      }
      int currentPoints = userDoc.data()?['membershipPoints'] ?? 0;

      int newPoints = currentPoints + additionalPoints;

      await _db.collection('users').doc(userId).update({
        'membershipPoints': newPoints,
      });

      return null;
    } catch (e) {
      return "Lỗi cập nhật điểm thành viên: ${e.toString()}";
    }
  }

  Future<String?> addMembershipCurrentPoints(
    String userId,
    int additionalPoints,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return "Không tìm thấy người dùng";
      }
      int currentPoints = userDoc.data()?['memberShipCurrentPoint'] ?? 0;

      int newPoints = currentPoints + additionalPoints;

      await _db.collection('users').doc(userId).update({
        'memberShipCurrentPoint': newPoints,
      });

      return null;
    } catch (e) {
      return "Lỗi cập nhật điểm thành viên: ${e.toString()}";
    }
  }

  Future<bool> getUser(String email) async {
    try {
      // Kiểm tra xem email có tồn tại trong Firebase Auth không
      var methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print("Lỗi kiểm tra người dùng: ${e.toString()}");
      return false;
    }
  }

  Future<String?> subtractMembershipCurrentPoints(
    String userId,
    int additionalPoints,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return "Không tìm thấy người dùng";
      }
      int currentPoints = userDoc.data()?['memberShipCurrentPoint'] ?? 0;

      int newPoints = currentPoints - additionalPoints;

      await _db.collection('users').doc(userId).update({
        'memberShipCurrentPoint': newPoints,
      });

      return null;
    } catch (e) {
      return "Lỗi cập nhật điểm thành viên: ${e.toString()}";
    }
  }

  Future<String?> subtractMembershipPoints(
    String userId,
    int pointsToSubtract,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return "Không tìm thấy người dùng";
      }

      int currentPoints = userDoc.data()?['membershipPoints'] ?? 0;

      if (currentPoints < pointsToSubtract) {
        return "Số điểm không đủ để thực hiện giao dịch";
      }

      int newPoints = currentPoints - pointsToSubtract;

      await _db.collection('users').doc(userId).update({
        'membershipPoints': newPoints,
      });

      return null;
    } catch (e) {
      return "Lỗi trừ điểm thành viên: ${e.toString()}";
    }
  }

  Future<String?> updateMembershipLevel(String userId, String newLevel) async {
    try {
      await _db.collection('users').doc(userId).update({
        'membershipLevel': newLevel,
      });
      return null;
    } catch (e) {
      return "Lỗi cập nhật cấp độ thành viên: ${e.toString()}";
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _db.collection("users").get();
      return querySnapshot.docs
          .where((doc) => doc.data()["email"] != "admin@gmail.com")
          .map((doc) {
            final data = doc.data();
            return UserModel(
              id: doc.id,
              email: data["email"] ?? "",
              fullName: data["fullName"] ?? "",
              address: data["address"],
              linkImage: data["imageLink"],
              memberShipPoint: data["membershipPoints"],
              memberShipCurrentPoint: data["memberShipCurrentPoint"],
              memberShipLevel: data["membershipLevel"],
            );
          })
          .toList();
    } catch (e) {
      print("Error getting all users: $e");
      return [];
    }
  }
}
