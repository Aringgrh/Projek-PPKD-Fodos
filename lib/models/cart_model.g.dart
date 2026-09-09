// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartModelFirebase _$CartModelFirebaseFromJson(Map<String, dynamic> json) =>
    CartModelFirebase(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      namaProduk: json['namaProduk'] as String? ?? '',
      namaToko: json['namaToko'] as String? ?? '',
      gambarUrl: json['gambarUrl'] as String? ?? '',
      harga: json['harga'] == null ? 0.0 : doubleFromDynamic(json['harga']),
      jumlah: json['jumlah'] == null ? 1 : intFromDynamic(json['jumlah']),
      catatan: json['catatan'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']),
      updatedAt: dateTimeFromJsonNullable(json['updatedAt']),
    );

Map<String, dynamic> _$CartModelFirebaseToJson(CartModelFirebase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'productId': instance.productId,
      'namaProduk': instance.namaProduk,
      'namaToko': instance.namaToko,
      'gambarUrl': instance.gambarUrl,
      'harga': instance.harga,
      'jumlah': instance.jumlah,
      'catatan': instance.catatan,
      'createdAt': dateTimeToJson(instance.createdAt),
      'updatedAt': dateTimeToJson(instance.updatedAt),
    };
