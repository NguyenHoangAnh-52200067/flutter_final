import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:ecommerce_app/repository/user_repository.dart';

class AdminInboxScreen extends StatelessWidget {
  AdminInboxScreen({super.key});
  UserModel? user;
  final UserRepository _userRepository = UserRepository();

  String getRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  String getFormattedTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return DateFormat.Hm().format(dateTime);
    } else if (difference.inDays < 7) {
      return timeago.format(dateTime, locale: 'vi');
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  Future<String> loadUserData(String userId) async {
    try {
      user = await _userRepository.getUserDetails(userId);
      if (user == null || user!.linkImage == null) {
        return "";
      }
      return user!.linkImage.toString();
    } catch (e) {
      print("Error loading user data: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.blue,
        centerTitle: false,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .orderBy('lastTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: chats.length,
            separatorBuilder:
                (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final userId = chat['userId'];
              final customerName = chat['customerName'] ?? 'Người dùng';
              final lastMessage =
                  (chat['lastMessage'] as String).trim().isEmpty
                      ? 'Đã gửi hình ảnh'
                      : chat['lastMessage'];
              final roomId = chat['userId'] + '_admin';
              final timestamp = chat['lastTimestamp'] as Timestamp;
              final isUnread = chat['adminUnread'] == true;
              final userInitial = customerName[0].toUpperCase();
              final imageUrl = loadUserData(userId);

              final color =
                  Colors.primaries[userId.hashCode % Colors.primaries.length];

              return InkWell(
                onTap: () async {
                  if (isUnread) {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(roomId)
                        .update({'adminUnread': false});
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(roomId: roomId, fromAdmin: true),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<String>(
                        future: loadUserData(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                              radius: 26,
                              backgroundColor: color.withOpacity(0.8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            );
                          }

                          final imageUrl = snapshot.data ?? "";
                          return Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: color.withOpacity(0.8),
                                child:
                                    imageUrl.isEmpty
                                        ? Text(
                                          userInitial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : CircleAvatar(
                                          radius: 25,
                                          backgroundImage: NetworkImage(
                                            imageUrl,
                                          ),
                                        ),
                              ),
                              if (isUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    height: 14,
                                    width: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  customerName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  getFormattedTime(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnread ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isUnread
                                              ? Colors.black87
                                              : Colors.grey[600],
                                      fontWeight:
                                          isUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Mới',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
