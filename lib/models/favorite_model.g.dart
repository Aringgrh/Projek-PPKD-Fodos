// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteModelFirebase _$FavoriteModelFirebaseFromJson(
  Map<String, dynamic> json,
) => FavoriteModelFirebase(
  id: json['id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  productId: json['productId'] as String? ?? '',
  namaProduk: json['namaProduk'] as String? ?? '',
  namaToko: json['namaToko'] as String? ?? '',
  kategori: json['kategori'] as String? ?? '',
  gambarUrl: json['gambarUrl'] as String? ?? '',
  harga: json['harga'] == null ? 0.0 : doubleFromDynamic(json['harga']),
  createdAt: dateTimeFromJson(json['createdAt']),
);

Map<String, dynamic> _$FavoriteModelFirebaseToJson(
  FavoriteModelFirebase instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'productId': instance.productId,
  'namaProduk': instance.namaProduk,
  'namaToko': instance.namaToko,
  'kategori': instance.kategori,
  'gambarUrl': instance.gambarUrl,
  'harga': instance.harga,
  'createdAt': dateTimeToJson(instance.createdAt),
};
