import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'firestrore_datetime.dart';

part 'favorite_model.g.dart';

/// Model data untuk item favorit yang tersimpan di Firestore.
/// Cocok untuk koleksi `favorites` atau subkoleksi `users/{userId}/favorites`.
@JsonSerializable(explicitToJson: true)
class FavoriteModelFirebase {
  /// Document ID di Firestore.
  @JsonKey(defaultValue: '')
  final String id;

  /// UID pengguna yang memfavoritkan produk.
  @JsonKey(defaultValue: '')
  final String userId;

  /// ID produk yang difavoritkan (merujuk ke Document ID pada koleksi `products`).
  @JsonKey(defaultValue: '')
  final String productId;

  /// Snapshot informasi produk untuk mempermudah render UI tanpa query ganda.
  @JsonKey(defaultValue: '')
  final String namaProduk;

  @JsonKey(defaultValue: '')
  final String namaToko;

  @JsonKey(defaultValue: '')
  final String kategori;

  @JsonKey(defaultValue: '')
  final String gambarUrl;

  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double harga;

  /// Waktu produk ditambahkan ke daftar favorit.
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;

  FavoriteModelFirebase({
    this.id = '',
    required this.userId,
    required this.productId,
    this.namaProduk = '',
    this.namaToko = '',
    this.kategori = '',
    this.gambarUrl = '',
    this.harga = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Alias getter gambar untuk render UI
  String get gambar => gambarUrl;

  /// Alias getter produkId untuk kompatibilitas
  String get produkId => productId;

  FavoriteModelFirebase copyWith({
    String? id,
    String? userId,
    String? productId,
    String? namaProduk,
    String? namaToko,
    String? kategori,
    String? gambarUrl,
    double? harga,
    DateTime? createdAt,
  }) {
    return FavoriteModelFirebase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      namaProduk: namaProduk ?? this.namaProduk,
      namaToko: namaToko ?? this.namaToko,
      kategori: kategori ?? this.kategori,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      harga: harga ?? this.harga,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Membuat instance [FavoriteModelFirebase] dari Map / JSON Firestore.
  factory FavoriteModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$FavoriteModelFirebaseFromJson(json);

  /// Factory untuk membuat instance langsung dari [DocumentSnapshot] Firestore.
  factory FavoriteModelFirebase.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final mapWithId = Map<String, dynamic>.from(data)..['id'] = doc.id;
    return FavoriteModelFirebase.fromJson(mapWithId);
  }

  /// Helper factory untuk konversi Map generik.
  factory FavoriteModelFirebase.fromMap(Map<String, dynamic> map) =>
      FavoriteModelFirebase.fromJson(map);

  /// Mengonversi model ke Map JSON.
  Map<String, dynamic> toJson() => _$FavoriteModelFirebaseToJson(this);

  /// Mengonversi ke Map khusus penyimpanan dokumen Firestore (tanpa id dokumen).
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Alias untuk [toJson].
  Map<String, dynamic> toMap() => toJson();
}

/// Type aliases
typedef FavoritModelFirebase = FavoriteModelFirebase;
typedef FavoriteModel = FavoriteModelFirebase;
typedef FavoritModel = FavoriteModelFirebase;
