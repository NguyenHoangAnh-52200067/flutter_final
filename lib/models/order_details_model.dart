import 'product_model.dart'; // nếu tách file

class OrderDetailsModel {
  String? orderId;
  ProductModel product;
  int quantity;
  double totalPrice;
  double revenue;

  OrderDetailsModel({
    this.orderId,
    required this.product,
    required this.quantity,
    required this.revenue,
  }) : totalPrice = quantity * product.price;

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      orderId: json['orderId'],
      revenue: (json['revenue'] as num).toDouble(),
      product: ProductModel.fromJson(json['product'], json['product']['id']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'product': product.toJson(),
      'revenue': revenue,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
