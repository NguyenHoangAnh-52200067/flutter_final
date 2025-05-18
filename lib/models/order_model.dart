import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_details_model.dart';

class OrderModel {
  String id; // Firestore document ID
  String customerName;
  String customerId; // ID của người dùng
  String customerPhone;
  String customerEmail;
  String shippingAddress;
  String shippingMethod;
  String shippingFee; // phí vận chuyển
  String? voucherCode; // mã giảm giá
  DateTime orderDate; // ngày đặt hàng
  DateTime? acceptDate; // ngày duyệt đơn
  DateTime? shippingDate; // ngày vận chuyển
  DateTime? deliveryDate;
  DateTime? paymentDate; // ngày hoàn thành
  double? conversionPoint;
  double totalAmount;
  String paymentMethod;
  double revenue;
  String status; // ví dụ: "Đang xử lý", "Hoàn thành"
  List<OrderDetailsModel> orderDetails;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.paymentMethod,
    required this.customerEmail,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.shippingMethod,
    required this.shippingFee,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.orderDetails,
    this.voucherCode,
    this.acceptDate,
    this.shippingDate,
    this.deliveryDate,
    this.paymentDate,
    required this.revenue,
    this.conversionPoint,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String docId) {
    var detailsJson = json['orderDetails'] as List<dynamic>? ?? [];
    List<OrderDetailsModel> details =
        detailsJson
            .map(
              (e) => OrderDetailsModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

    return OrderModel(
      id: docId,
      customerId: json['customerId'],
      paymentMethod: json['paymentMethod'],
      customerEmail: json['customerEmail'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      shippingMethod: json['shippingMethod'],
      shippingFee: json['shippingFee'],
      shippingAddress: json['shippingAddress'],
      orderDate: (json['orderDate'] as Timestamp).toDate(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      orderDetails: details,
      revenue: (json['revenue'] as num).toDouble(),
      voucherCode: json['voucherCode'],
      acceptDate: (json['acceptDate'] as Timestamp?)?.toDate(),
      shippingDate: (json['shippingDate'] as Timestamp?)?.toDate(),
      deliveryDate: (json['deliveryDate'] as Timestamp?)?.toDate(),
      paymentDate: (json['paymentDate'] as Timestamp?)?.toDate(),
      conversionPoint: (json['conversionPoint'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'orderDate': Timestamp.fromDate(orderDate),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'customerEmail': customerEmail,
      'shippingMethod': shippingMethod,
      'shippingFee': shippingFee,
      'voucherCode': voucherCode,
      'revenue': revenue,
      'status': status,
      'conversionPoint': conversionPoint,
      'orderDetails': orderDetails.map((e) => e.toJson()).toList(),
      'acceptDate': acceptDate != null ? Timestamp.fromDate(acceptDate!) : null,
      'shippingDate':
          shippingDate != null ? Timestamp.fromDate(shippingDate!) : null,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'paymentDate':
          paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
    };
  }
}
