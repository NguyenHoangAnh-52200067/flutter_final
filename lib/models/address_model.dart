class AddressModel {
  final String? userId;
  final String city;
  final String district;
  final String ward;
  final String? street;
  final String? local;
  final String fullAddress;
  final String userName;
  final String userPhone;
  final bool isDefault;
  final String userMail;
  final String addressId;

  AddressModel({
    required this.addressId,
    this.userId,
    required this.city,
    required this.district,
    required this.ward,
    this.street,
    this.local,
    required this.fullAddress,
    required this.userName,
    required this.userPhone,
    this.isDefault = false,
    required this.userMail,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      addressId: json['addressId'] ?? '',
      userId: json['userId'],
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      ward: json['ward'] ?? '',
      street: json['street'] ?? '',
      local: json['local'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      isDefault: json['isDefault'] ?? false,
      userMail: json['userMail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'userId': userId,
      'city': city,
      'district': district,
      'ward': ward,
      'street': street,
      'local': local,
      'fullAddress': fullAddress,
      'userName': userName,
      'userPhone': userPhone,
      'isDefault': isDefault,
      'userMail': userMail,
    };
  }
}
