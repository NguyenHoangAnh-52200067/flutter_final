class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String? variantName;
  final String? imageUrl;
  final double price;
  final double? priceAfterDiscount;
  final double costPrice;
  int quantity;
  final double discountRate;

  CartItem({
    required this.id,
    required this.costPrice,
    required this.productId,
    required this.productName,
    this.priceAfterDiscount,
    this.variantName,
    this.imageUrl,
    required this.price,
    required this.quantity,
    this.discountRate = 0,
  });

  // Tính tổng tiền của item này
  double get totalPrice {
    double discountedPrice =
        discountRate > 0 ? price * (1 - discountRate / 100) : price;
    return discountedPrice * quantity;
  }

  // Phương thức tạo bản sao CartItem với các thuộc tính có thể thay đổi
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? variantName,
    String? imageUrl,
    double? price,
    int? quantity,
    double? priceAfterDiscount,
    double? costPrice,
    double? discountRate,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      costPrice: costPrice ?? this.costPrice,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discountRate: discountRate ?? this.discountRate,
      priceAfterDiscount: priceAfterDiscount ?? this.priceAfterDiscount,
    );
  }

  // Chuyển đổi CartItem thành Map để lưu vào Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'variantName': variantName,
      'costPrice': costPrice,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'discountRate': discountRate,
      'priceAfterDiscount': priceAfterDiscount,
    };
  }

  // Tạo CartItem từ Map (để đọc từ Database)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['productId'],
      costPrice: map['costPrice'],
      productName: map['productName'],
      variantName: map['variantName'],
      imageUrl: map['imageUrl'],
      price: map['price'],
      quantity: map['quantity'],
      discountRate: map['discountRate'],
      priceAfterDiscount: map['priceAfterDiscount'],
    );
  }
}
