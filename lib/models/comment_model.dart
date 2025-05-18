class CommentModel {
  String? id;
  String productId;
  String? userId;
  String userName;
  String content;
  double? rating;
  String? orderId;
  DateTime createdAt;
  String? reply;
  DateTime? replyAt = null;

  CommentModel({
    this.id,
    required this.productId,
    this.userId,
    required this.userName,
    required this.content,
    this.rating,
    this.orderId,
    required this.createdAt,
    this.reply,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'rating': rating,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'],
      userName: json['userName'],
      content: json['content'],
      rating: json['rating']?.toDouble(),
      orderId: json['orderId'],
      createdAt: DateTime.parse(json['createdAt']),
      reply: json['reply'],
    );
  }
}
