import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecommerce_app/utils/image_upload.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _UploadingImage {
  final File file;
  String? url;
  bool isUploading;

  _UploadingImage({required this.file, this.url, this.isUploading = true});
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserRepository _userRepo = UserRepository();

  String? _fullName;
  bool _isAdmin = false;
  bool _isComposing = false;
  Map<String, dynamic>? _tempMessage;

  final Color primaryColor = Color(0xFF6C63FF);
  final Color secondaryColor = Color(0xFFE8E6FF);
  final Color backgroundColor = Color(0xFFF9F9FB);
  final Color myMessageColor = Color(0xFF6C63FF);
  final Color otherMessageColor = Color(0xFFF5F5F7);
  final Color textLightColor = Color(0xFF9E9E9E);

  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();
  List<File> _pendingImages = [];

  List<_UploadingImage> _uploadingImages = [];
  @override
  void initState() {
    super.initState();
    _getChatRoomUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles == null) return;

    List<_UploadingImage> newUploads =
        pickedFiles.map((xfile) {
          return _UploadingImage(file: File(xfile.path), isUploading: false);
        }).toList();

    setState(() {
      _uploadingImages.addAll(newUploads);
      _isComposing = true;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _uploadingImages.removeAt(index);
    });
  }

  final ImagePicker _picker = ImagePicker();

  Future<File?> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _getChatRoomUserName() async {
    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.roomId)
            .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      setState(() {
        _isAdmin =
            FirebaseAuth.instance.currentUser?.email == 'admin@gmail.com';
        _fullName = data?['customerName'] ?? 'Người dùng ẩn danh';
      });
    }
  }

  Future<void> _sendMessage(
    String text,
    TextEditingController controller,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null ||
        (text.trim().isEmpty && _uploadingImages.isEmpty)) {
      print("null");
      return;
    }

    final tempImages = List<_UploadingImage>.from(_uploadingImages);
    final tempImageFiles = tempImages.map((img) => img.file).toList();
    final tempMessageText = text;

    controller.clear();

    if (!tempImageFiles.isEmpty) {
      setState(() {
        _tempMessage = {
          'text': tempMessageText,
          'senderId': currentUser.uid,
          'timestamp': Timestamp.now(),
          'tempImages': tempImageFiles,
        };

        _uploadingImages.clear();
        _isComposing = false;
      });
    }

    List<String> imageUrls = [];
    for (int i = 0; i < tempImages.length; i++) {
      final img = tempImages[i];
      final uploadedUrl = await _imageUploadService.uploadImage(img.file);
      imageUrls.add(uploadedUrl);
    }

    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId);
    final messagesRef = chatDocRef.collection('messages');

    final parts = widget.roomId.split('_');
    final uid1 = parts[0];
    final uid2 = parts[1];
    final customerId = (uid1 == 'admin') ? uid2 : uid1;
    UserModel? userModel = await _userRepo.getUserDetails(customerId);
    final customerName = userModel?.fullName ?? 'Người dùng';
    final chatDocSnapshot = await chatDocRef.get();
    final originalUserId = chatDocSnapshot.data()?['userId'] ?? customerId;

    await messagesRef.add({
      'text': tempMessageText,
      'images': imageUrls,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      _tempMessage = null;
    });
    await chatDocRef.set({
      'lastMessage': tempMessageText,
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

  Widget _buildClickableImage(String url) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (_) =>
                  Dialog(child: InteractiveViewer(child: Image.network(url))),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 160, height: 160, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTempImagePreview(File file) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
          opacity: 0.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      .doc(widget.roomId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                final allMessages = List<Map<String, dynamic>>.from(
                  messages.map((doc) => doc.data() as Map<String, dynamic>),
                );

                // Thêm tin nhắn giả nếu có
                if (_tempMessage != null) {
                  allMessages.add(_tempMessage!);
                }

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    final isMe = message['senderId'] == userId;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final time = _formatTimestamp(timestamp);
                    final isTemp = message == _tempMessage;

                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevTimestamp =
                          allMessages[index - 1]['timestamp'] as Timestamp?;
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
                        _buildMessageBubble(message, isMe, time, isTemp),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_uploadingImages.isNotEmpty)
          Container(
            height: 90,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadingImages.length,
              itemBuilder: (context, index) {
                final img = _uploadingImages[index];
                return Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(img.file),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child:
                          img.isUploading
                              ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : null,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        Row(
          children: [
            IconButton(icon: Icon(Icons.image), onPressed: _pickImages),
            Expanded(
              child: TextField(
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                controller: _controller,
                decoration: InputDecoration(hintText: 'Nhập tin nhắn...'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed:
                  (_isComposing || _uploadingImages.isNotEmpty)
                      ? () => _sendMessage(_controller.text, _controller)
                      : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(File file, bool isUploading) {
    final index = _pendingImages.indexOf(file);
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 8),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
          child:
              isUploading
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
        ),
        if (!isUploading)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _pendingImages.removeAt(index)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSeparator(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

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
    Map<String, dynamic> message,
    bool isMe,
    String time,
    bool isTemp,
  ) {
    final hasText = (message['text'] as String?)?.isNotEmpty ?? false;
    List<dynamic> imageContent = [];

    if (isTemp && message['tempImages'] != null) {
      // Hiển thị ảnh từ file cho tin nhắn giả
      imageContent = message['tempImages'] as List<dynamic>;
    } else if (message['images'] != null) {
      // Hiển thị ảnh từ URL cho tin nhắn thật
      imageContent = List<String>.from(message['images']);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMe
                  ? (isTemp ? Colors.blue[50] : Colors.blue[100])
                  : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageContent.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    isTemp
                        ? imageContent
                            .map((file) => _buildTempImagePreview(file))
                            .toList()
                        : (imageContent as List<String>)
                            .map((url) => _buildClickableImage(url))
                            .toList(),
              ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message['text']),
              ),
            Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isTemp ? 'Đang gửi...' : time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : textLightColor,
                      fontSize: 11,
                      fontStyle: isTemp ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (isTemp)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMe ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(tag: imageUrl, child: Image.network(imageUrl)),
        ),
      ),
    );
  }
}
