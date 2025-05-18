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
  final bool fromAdmin;
  const ChatScreen({super.key, required this.roomId, this.fromAdmin = false});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _UploadingImage {
  final File file;
  String? url;
  bool isUploading;

  _UploadingImage({required this.file, this.url, this.isUploading = true});
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserRepository _userRepo = UserRepository();

  // Add pagination constants and variables
  static const int _messagesPerPage = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  String? _fullName;
  bool _isAdmin = false;
  bool _isComposing = false;
  Map<String, dynamic>? _tempMessage;

  final Color primaryColor = Color(
    0xFF2196F3,
  ); // Changed from 0xFF6C63FF to blue
  final Color secondaryColor = Color(0xFFE3F2FD); // Changed to light blue
  final Color backgroundColor = Color(0xFFF9F9FB);
  final Color myMessageColor = Color(
    0xFF2196F3,
  ); // Changed from 0xFF6C63FF to blue
  final Color otherMessageColor = Color(0xFFF5F5F7);
  final Color textLightColor = Color(0xFF9E9E9E);
  final Color accentColor = Color(0xFF1976D2); // Changed to darker blue

  final ImageUploadService _imageUploadService =
      ImageUploadService.getInstance();
  List<_UploadingImage> _uploadingImages = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  Future<void> _handleBack() async {
    if (widget.fromAdmin) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.roomId)
          .update({'adminUnread': false});
    }
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _getChatRoomUserName();
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Add scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  // Method to load more messages when scrolling up
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.roomId)
          .collection('messages');

      // Get the current messages to find the oldest one
      final currentMessages =
          await messagesRef
              .orderBy('timestamp', descending: true)
              .limit(_currentPage * _messagesPerPage)
              .get();

      if (currentMessages.docs.length < _currentPage * _messagesPerPage) {
        // No more messages to load
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Increment page for next load
      setState(() {
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      print('Error loading more messages: $e');
    }
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
      _isComposing =
          _controller.text.trim().isNotEmpty || _uploadingImages.isNotEmpty;
    });
  }

  final ImagePicker _picker = ImagePicker();

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
      return;
    }

    final tempImages = List<_UploadingImage>.from(_uploadingImages);
    final tempImageFiles = tempImages.map((img) => img.file).toList();
    final tempMessageText = text;

    controller.clear();

    if (tempImageFiles.isNotEmpty) {
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

    bool adminUnread = currentUser.uid != 'admin';

    await chatDocRef.set({
      'lastMessage':
          tempMessageText.isEmpty && imageUrls.isNotEmpty
              ? '[Hình ảnh]'
              : tempMessageText,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'userId': originalUserId,
      'customerName': customerName,
      'adminUnread': adminUnread,
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(imageUrl: url),
          ),
        );
      },
      child: Hero(
        tag: url,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.error_outline, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTempImagePreview(File file) {
    return Container(
      width: 80,
      height: 80,
      margin: EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
    );
  }

  // Add this method to show a loading indicator when fetching more messages
  Widget _buildLoadingMoreIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              await _handleBack();
            },
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                radius: 20,
                child:
                    _isAdmin
                        ? Text(
                          _fullName?.isNotEmpty == true
                              ? _fullName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                        : Icon(
                          Icons.support_agent,
                          color: primaryColor,
                          size: 22,
                        ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAdmin ? _fullName ?? "Hỗ trợ" : 'Trung tâm hỗ trợ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isAdmin ? 'Khách hàng' : 'Đang hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text('Xóa cuộc trò chuyện'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.block, color: Colors.orange),
                              title: Text('Chặn người dùng'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            if (_isAdmin)
                              ListTile(
                                leading: Icon(
                                  Icons.info_outline,
                                  color: primaryColor,
                                ),
                                title: Text('Thông tin khách hàng'),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                      ),
                );
              },
            ),
          ],
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
                        .orderBy('timestamp', descending: true)
                        .limit(_currentPage * _messagesPerPage)
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

                  // Reverse to show in chronological order
                  allMessages.sort((a, b) {
                    final aTime = a['timestamp'] as Timestamp?;
                    final bTime = b['timestamp'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return aTime.compareTo(bTime);
                  });

                  if (_tempMessage != null) {
                    allMessages.add(_tempMessage!);
                  }

                  if (allMessages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 16),
                          Text(
                            'Chưa có tin nhắn nào',
                            style: TextStyle(color: textLightColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: allMessages.length + (_hasMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the top when loading more
                      if (index == 0 && _isLoadingMore) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Adjust index if showing loading indicator
                      final messageIndex = _isLoadingMore ? index - 1 : index;
                      if (messageIndex < 0 ||
                          messageIndex >= allMessages.length) {
                        return SizedBox.shrink();
                      }

                      final message = allMessages[messageIndex];
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

                      bool showAvatar = true;
                      if (index > 0) {
                        final prevMessage = allMessages[index - 1];
                        if (prevMessage['senderId'] == message['senderId']) {
                          if (timestamp != null &&
                              prevMessage['timestamp'] != null) {
                            final prevTime =
                                (prevMessage['timestamp'] as Timestamp)
                                    .toDate();
                            final currTime = timestamp.toDate();
                            if (currTime.difference(prevTime).inMinutes < 2) {
                              showAvatar = false;
                            }
                          }
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator && timestamp != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: _buildDateSeparator(timestamp),
                            ),
                          _buildMessageBubble(
                            message,
                            isMe,
                            time,
                            isTemp,
                            showAvatar,
                          ),
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
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_uploadingImages.isNotEmpty)
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadingImages.length,
                itemBuilder: (context, index) {
                  final img = _uploadingImages[index];
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 12, top: 4),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: FileImage(img.file),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child:
                            img.isUploading
                                ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.black87,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.photo_library_outlined,
                      color: primaryColor,
                    ),
                    onPressed: _pickImages,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      onChanged: (text) {
                        setState(() {
                          _isComposing =
                              text.trim().isNotEmpty ||
                              _uploadingImages.isNotEmpty;
                        });
                      },
                      controller: _controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isComposing ? primaryColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded),
                    color: _isComposing ? Colors.white : Colors.grey[600],
                    onPressed:
                        _isComposing
                            ? () => _sendMessage(_controller.text, _controller)
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isMe,
    String time,
    bool isTemp,
    bool showAvatar,
  ) {
    final text = message['text'] as String? ?? '';
    final images = message['images'] as List<dynamic>? ?? [];
    final tempImages = message['tempImages'] as List<File>? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              radius: 16,
              child: Icon(Icons.support_agent, color: primaryColor, size: 18),
            )
          else if (!isMe && !showAvatar)
            SizedBox(width: 32),

          if (!isMe) SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),

                  // Images
                  if (images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            images
                                .map(
                                  (url) => _buildClickableImage(url.toString()),
                                )
                                .toList(),
                      ),
                    ),

                  // Temp images
                  if (tempImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            tempImages
                                .map((file) => _buildTempImagePreview(file))
                                .toList(),
                      ),
                    ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        if (isTemp)
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: isMe ? Colors.white70 : Colors.black38,
                          )
                        else
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.black38,
                            ),
                          ),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.done_all,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) SizedBox(width: 8),

          if (isMe && showAvatar)
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 16,
              child: Text(
                'Me',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            )
          else if (isMe && !showAvatar)
            SizedBox(width: 32),
        ],
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
