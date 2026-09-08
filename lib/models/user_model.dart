import 'package:json_annotation/json_annotation.dart';
import 'firestrore_datetime.dart';

part 'user_model.g.dart';

/// Model data untuk menyimpan informasi profil pengguna di koleksi `users` Firestore.
@JsonSerializable(explicitToJson: true)
class UserModelFirebase {
  /// Unique Identifier (UID) dari Firebase Authentication.
  @JsonKey(defaultValue: '')
  final String uid;

  /// Nama lengkap pengguna.
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String nomor;

  /// Alamat email pengguna.
  @JsonKey(defaultValue: '')
  final String email;

  @JsonKey(defaultValue: '')
  final String alamat;

  /// Tanggal registrasi pengguna yang disimpan sebagai Timestamp di Firestore.
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;

  UserModelFirebase({
    required this.uid,
    required this.name,
    required this.nomor,
    required this.email,
    required this.alamat,
    required this.createdAt,
  });

  UserModelFirebase copyWith({
    String? uid,
    String? name,
    String? nomor,
    String? email,
    String? alamat,
    DateTime? createdAt,
  }) {
    return UserModelFirebase(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nomor: nomor ?? this.nomor,
      email: email ?? this.email,
      alamat: alamat ?? this.alamat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mengonversi Map JSON menjadi objek [UserModelFirebase].
  factory UserModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$UserModelFirebaseFromJson(json);

  /// Helper factory untuk mengubah Map data Firestore menjadi [UserModelFirebase].
  factory UserModelFirebase.fromMap(Map<String, dynamic> map) =>
      UserModelFirebase.fromJson(map);

  /// Mengonversi instans [UserModelFirebase] menjadi Map JSON.
  Map<String, dynamic> toJson() => _$UserModelFirebaseToJson(this);

  /// Alias method [toJson] untuk menyimpan data ke dokumen Firestore.
  Map<String, dynamic> toMap() => toJson();
}

typedef UserModel = UserModelFirebase;
