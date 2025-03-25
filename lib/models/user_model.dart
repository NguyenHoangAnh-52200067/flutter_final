class UserModel {
  String? id;
  String email;
  String fullName;
  String address;
  String? linkImage;

  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    required this.address,
    this.linkImage,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "fullName": fullName,
      "address": address,
      "imageLink": linkImage,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      email: json["email"],
      fullName: json["fullName"],
      address: json["address"],
      linkImage: json["imageLink"],
    );
  }
}