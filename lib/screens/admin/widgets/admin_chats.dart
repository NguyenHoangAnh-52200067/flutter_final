import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminInboxScreen extends StatelessWidget {
  const AdminInboxScreen({super.key});

  String getRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn đến từ người dùng')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .orderBy('lastTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final userId = chat['userId'];
              final customerName = chat['customerName'] ?? 'Người dùng';
              final lastMessage = chat['lastMessage'] ?? '';
              final roomId = chat['userId'] + '_admin';

              return ListTile(
                leading: CircleAvatar(child: Text(customerName[0])),
                title: Text(customerName),
                subtitle: Text(lastMessage),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(roomId: roomId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
