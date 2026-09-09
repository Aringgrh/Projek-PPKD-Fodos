// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModelFirebase _$ProductModelFirebaseFromJson(
  Map<String, dynamic> json,
) => ProductModelFirebase(
  id: json['id'] as String? ?? '',
  namaProduk: json['namaProduk'] as String? ?? '',
  namaToko: json['namaToko'] as String? ?? '',
  kategori: json['kategori'] as String? ?? '',
  gambarUrl: json['gambarUrl'] as String? ?? '',
  harga: json['harga'] == null ? 0.0 : doubleFromDynamic(json['harga']),
  stok: json['stok'] == null ? 0 : intFromDynamic(json['stok']),
  deskripsi: json['deskripsi'] as String? ?? '',
  createdAt: dateTimeFromJson(json['createdAt']),
);

Map<String, dynamic> _$ProductModelFirebaseToJson(
  ProductModelFirebase instance,
) => <String, dynamic>{
  'id': instance.id,
  'namaProduk': instance.namaProduk,
  'namaToko': instance.namaToko,
  'kategori': instance.kategori,
  'gambarUrl': instance.gambarUrl,
  'harga': instance.harga,
  'stok': instance.stok,
  'deskripsi': instance.deskripsi,
  'createdAt': dateTimeToJson(instance.createdAt),
};
