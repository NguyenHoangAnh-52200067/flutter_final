class CategoryModel {
  String? id;
  String name;
  String? imageUrl;
  String? parentId;

  CategoryModel({this.id, required this.name, required this.imageUrl, this.parentId});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "imageUrl": imageUrl,
      "parentId": parentId,
    };
  }

  
  factory CategoryModel.fromJson(Map<String, dynamic> json, String docId) {
    return CategoryModel(
      id: docId,
      name: json["name"],
      imageUrl: json["imageUrl"] ?? "",
      parentId: json["parentId"],
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? parentId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
    );
  }
}
