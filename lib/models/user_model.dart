class UserModel {
  String? id;
  String email;
  String fullName;
  String? address;
  String? linkImage;
  bool isBanned = false;

  int? memberShipPoint;
  int? memberShipCurrentPoint;
  String? memberShipLevel;
  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    this.address,
    this.linkImage,
    this.memberShipPoint = 0,
    this.memberShipCurrentPoint = 0,
    this.memberShipLevel = 'Thành viên',
    this.isBanned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "fullName": fullName,
      "address": address,
      "imageLink": linkImage,
      "memberShipPoints": memberShipPoint,
      "memberShipLevel": memberShipLevel,
      "memberShipCurrentPoint": memberShipCurrentPoint,
      "isBanned": isBanned,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      email: json["email"],
      fullName: json["fullName"],
      address: json["address"],
      linkImage: json["imageLink"],
      memberShipPoint: json["memberShipPoints"],
      memberShipLevel: json["memberShipLevel"],
      memberShipCurrentPoint: json["memberShipCurrentPoint"],
      isBanned: json["isBanned"] ?? false,
    );
  }
}
