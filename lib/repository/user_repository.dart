import 'package:ecomerce_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          duration: const Duration(seconds: 2),
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

  Future<String?> updateUser(String userId, UserModel user) async {
    try {
      await _db.collection('users').doc(userId).update(user.toJson());
      return null;
    } catch (e) {
      return "Lỗi cập nhật thông tin: ${e.toString()}";
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return null;
      } else {
        return "Người dùng chưa đăng nhập.";
      }
    } catch (e) {
      return "Lỗi đổi mật khẩu: ${e.toString()}";
    }
  }
}
