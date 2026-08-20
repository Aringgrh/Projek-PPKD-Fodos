import 'dart:convert';

class FavoritModel {
  final int? id;
  final int userId;
  final int produkId;

  FavoritModel({
    this.id,
    required this.userId,
    required this.produkId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'produk_id': produkId,
    };
  }

  factory FavoritModel.fromMap(Map<String, dynamic> map) {
    return FavoritModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: (map['user_id'] ?? 0) as int,
      produkId: (map['produk_id'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory FavoritModel.fromJson(String source) =>
      FavoritModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
