// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModelFirebase _$UserModelFirebaseFromJson(Map<String, dynamic> json) =>
    UserModelFirebase(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nomor: json['nomor'] as String? ?? '',
      email: json['email'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']),
    );

Map<String, dynamic> _$UserModelFirebaseToJson(UserModelFirebase instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'nomor': instance.nomor,
      'email': instance.email,
      'alamat': instance.alamat,
      'createdAt': dateTimeToJson(instance.createdAt),
    };
