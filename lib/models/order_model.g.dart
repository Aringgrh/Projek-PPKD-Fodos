// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      productId: json['productId'] as String? ?? '',
      namaProduk: json['namaProduk'] as String? ?? '',
      namaToko: json['namaToko'] as String? ?? '',
      gambarUrl: json['gambarUrl'] as String? ?? '',
      harga: json['harga'] == null ? 0.0 : doubleFromDynamic(json['harga']),
      jumlah: json['jumlah'] == null ? 1 : intFromDynamic(json['jumlah']),
      catatan: json['catatan'] as String? ?? '',
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'namaProduk': instance.namaProduk,
      'namaToko': instance.namaToko,
      'gambarUrl': instance.gambarUrl,
      'harga': instance.harga,
      'jumlah': instance.jumlah,
      'catatan': instance.catatan,
    };

OrderModelFirebase _$OrderModelFirebaseFromJson(Map<String, dynamic> json) =>
    OrderModelFirebase(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      alamatPengiriman: json['alamatPengiriman'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalHarga: json['totalHarga'] == null
          ? 0.0
          : doubleFromDynamic(json['totalHarga']),
      totalItem: json['totalItem'] == null
          ? 0
          : intFromDynamic(json['totalItem']),
      ongkir: json['ongkir'] == null ? 0.0 : doubleFromDynamic(json['ongkir']),
      metodePembayaran: json['metodePembayaran'] as String? ?? 'Tunai',
      status: json['status'] as String? ?? 'Diproses',
      catatan: json['catatan'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']),
      updatedAt: dateTimeFromJsonNullable(json['updatedAt']),
    );

Map<String, dynamic> _$OrderModelFirebaseToJson(OrderModelFirebase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhone': instance.userPhone,
      'alamatPengiriman': instance.alamatPengiriman,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalHarga': instance.totalHarga,
      'totalItem': instance.totalItem,
      'ongkir': instance.ongkir,
      'metodePembayaran': instance.metodePembayaran,
      'status': instance.status,
      'catatan': instance.catatan,
      'createdAt': dateTimeToJson(instance.createdAt),
      'updatedAt': dateTimeToJson(instance.updatedAt),
    };
