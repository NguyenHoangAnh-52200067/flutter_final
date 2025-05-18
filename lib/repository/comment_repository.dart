import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/comment_model.dart';

class CommentRepository extends GetxController {
  static CommentRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> addComment(CommentModel comment) async {
    try {
      final docRef = _db.collection("comments").doc();
      comment.id = docRef.id;
      await docRef.set(comment.toJson());

      Get.snackbar(
        "Thành công",
        "Đã thêm bình luận",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (error) {
      Get.snackbar(
        "Lỗi",
        "Không thể thêm bình luận",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> replyToComment(String commentId, String replyText) async {
    await _db.collection("comments").doc(commentId).update({
      "reply": replyText,
      "replyAt": DateTime.now(),
    });
  }

  Future<List<CommentModel>> getProductComments(
    String productId, {
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await _db
              .collection("comments")
              .where('productId', isEqualTo: productId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
    } catch (error) {
      return [];
    }
  }
}
