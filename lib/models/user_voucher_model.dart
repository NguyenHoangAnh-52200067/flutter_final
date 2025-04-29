class UserVoucherModel {
  final String id;
  final String userId;
  final String voucherId;
  final String voucherCode;
  final bool isUsed;

  UserVoucherModel({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.voucherCode,
    this.isUsed = false,
  });

  factory UserVoucherModel.fromJson(Map<String, dynamic> json, String id) =>
      UserVoucherModel(
        id: id,
        userId: json['userId'],
        voucherId: json['voucherId'],
        voucherCode: json['voucherCode'],
        isUsed: json['isUsed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'voucherId': voucherId,
    'voucherCode': voucherCode,
    'isUsed': isUsed,
  };
}
