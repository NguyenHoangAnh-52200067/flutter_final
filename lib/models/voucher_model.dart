import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherModel {
  final String id;
  final String code;
  final double discountAmount;
  final int pointNeeded;
  final int maxUsage;
  final int currentUsage;
  final DateTime createdAt;
  final List<String> usedOrderIds;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.pointNeeded,
    this.maxUsage = 10,
    this.currentUsage = 0,
    required this.createdAt,
    this.usedOrderIds = const [],
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json, String id) {
    return VoucherModel(
      id: id,
      code: json['code'],
      pointNeeded: json['pointNeeded'] ?? 0,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      maxUsage: json['maxUsage'],
      currentUsage: json['currentUsage'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      usedOrderIds: List<String>.from(json['usedOrderIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'pointNeeded': pointNeeded,
    'id': id,
    'discountAmount': discountAmount,
    'maxUsage': maxUsage,
    'currentUsage': currentUsage,
    'createdAt': Timestamp.fromDate(createdAt),
    'usedOrderIds': usedOrderIds,
  };
  bool get isValid => currentUsage < maxUsage;
}
