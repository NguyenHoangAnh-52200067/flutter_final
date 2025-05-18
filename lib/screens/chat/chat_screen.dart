import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String roomId = 'room1';
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  final UserRepository _userRepo = UserRepository();
  String? _fullName;
  bool _isAdmin = false;

  final Color primaryColor = Color(0xFF6C63FF);
  final Color secondaryColor = Color(0xFFE8E6FF);
  final Color backgroundColor = Color(0xFFF9F9FB);
  final Color myMessageColor = Color(0xFF6C63FF);
  final Color otherMessageColor = Color(0xFFF5F5F7);
  final Color textLightColor = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    _getChatRoomUserName();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final threshold = 100;
      final shouldScroll =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - threshold;

      if (shouldScroll) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _openAppScroll() {
    final threshold = 100;
    final shouldScroll =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold;

    if (shouldScroll) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _getChatRoomUserName() async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection('chats').doc(roomId).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      setState(() {
        _isAdmin =
            FirebaseAuth.instance.currentUser?.email.toString() ==
            'admin@gmail.com';
        _fullName = data?['userName'] ?? 'Người dùng ẩn danh';
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || text.trim().isEmpty) return;

    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId);
    final messagesRef = chatDocRef.collection('messages');

    final parts = widget.roomId.split('_');
    final uid1 = parts[0];
    final uid2 = parts[1];
    final customerId = (uid1 == 'admin') ? uid2 : uid1;

    UserModel? userModel = await _userRepo.getUserDetails(currentUser.uid);
    final customerName = userModel?.fullName ?? 'Người dùng';
    final chatDocSnapshot = await chatDocRef.get();
    final originalUserId = chatDocSnapshot.data()?['userId'] ?? customerId;

    await messagesRef.add({
      'text': text,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatDocRef.set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'userId': originalUserId,
      'customerName': customerName,
    }, SetOptions(merge: true));
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageDate = timestamp.toDate();

    if (now.difference(messageDate).inDays == 0) {
      return DateFormat.Hm().format(messageDate);
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('E, HH:mm').format(messageDate);
    } else {
      return DateFormat('dd/MM, HH:mm').format(messageDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    _openAppScroll();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              radius: 18,
              child: Text(
                'R1',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdmin ? _fullName ?? "Hỗ trợ" : 'Trung tâm hỗ trợ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.withOpacity(0.2)),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(roomId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == userId;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final time = _formatTimestamp(timestamp);

                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevTimestamp =
                          messages[index - 1]['timestamp'] as Timestamp?;
                      if (prevTimestamp != null && timestamp != null) {
                        final prevDate = DateTime(
                          prevTimestamp.toDate().year,
                          prevTimestamp.toDate().month,
                          prevTimestamp.toDate().day,
                        );
                        final currentDate = DateTime(
                          timestamp.toDate().year,
                          timestamp.toDate().month,
                          timestamp.toDate().day,
                        );

                        if (prevDate != currentDate) {
                          showDateSeparator = true;
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (showDateSeparator && timestamp != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: _buildDateSeparator(timestamp),
                          ),

                        _buildMessageBubble(isMe, message, time),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(color: textLightColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _isComposing ? primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: _isComposing ? Colors.white : textLightColor,
                      ),
                      onPressed:
                          _isComposing
                              ? () async {
                                await _sendMessage(_controller.text);
                                _controller.clear();
                                setState(() {
                                  _isComposing = false;
                                });
                              }
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(Duration(days: 1));

    String dateText;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dateText = 'Hôm nay';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      dateText = 'Hôm qua';
    } else {
      dateText = DateFormat('dd/MM/yyyy').format(date);
    }

    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            dateText,
            style: TextStyle(
              color: textLightColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildMessageBubble(
    bool isMe,
    Map<String, dynamic> message,
    String time,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        decoration: BoxDecoration(
          color: isMe ? myMessageColor : otherMessageColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 16 : 4),
            topRight: Radius.circular(isMe ? 4 : 16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : textLightColor,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4),
                    Icon(Icons.done_all, size: 14, color: Colors.white70),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
