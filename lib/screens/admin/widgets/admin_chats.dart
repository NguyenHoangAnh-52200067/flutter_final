import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminInboxScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tin nhắn đến từ người dùng')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .orderBy('lastTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final userId = chat['userId'];
              final userName = chat['userName'] ?? 'Người dùng';
              final lastMessage = chat['lastMessage'] ?? '';
              final roomId = '${userId}_admin';

              return ListTile(
                leading: CircleAvatar(child: Text(userName[0])),
                title: Text(userName),
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
