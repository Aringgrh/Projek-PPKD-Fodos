import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'firestrore_datetime.dart';

part 'product_model.g.dart';

/// Model data produk yang terhubung langsung dengan koleksi `products` di Firebase Firestore.
@JsonSerializable(explicitToJson: true)
class ProductModelFirebase {
  /// Document ID dari Firestore.
  @JsonKey(defaultValue: '')
  final String id;

  /// Nama produk makanan/minuman.
  @JsonKey(defaultValue: '')
  final String namaProduk;

  /// Nama toko/warung penjual.
  @JsonKey(defaultValue: '')
  final String namaToko;

  /// Kategori produk (contoh: "Makanan Berat", "Roti", "Minuman", dll).
  @JsonKey(defaultValue: '')
  final String kategori;

  /// URL gambar produk.
  @JsonKey(defaultValue: '')
  final String gambarUrl;

  /// Harga produk (disimpan dalam satuan Rupiah).
  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double harga;

  /// Sisa stok produk.
  @JsonKey(fromJson: intFromDynamic, defaultValue: 0)
  final int stok;

  /// Deskripsi atau catatan detail mengenai produk.
  @JsonKey(defaultValue: '')
  final String deskripsi;

  /// Waktu pembuatan/penambahan produk ke Firestore.
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;

  ProductModelFirebase({
    this.id = '',
    required this.namaProduk,
    required this.namaToko,
    required this.kategori,
    required this.gambarUrl,
    required this.harga,
    required this.stok,
    this.deskripsi = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Menentukan apakah produk masih tersedia dalam stok.
  bool get isAvailable => stok > 0;

  /// Alias getter gambar untuk kemudahan rendering UI.
  String get gambar => gambarUrl;

  /// Helper copyWith untuk memperbarui properti model secara immutable.
  ProductModelFirebase copyWith({
    String? id,
    String? namaProduk,
    String? namaToko,
    String? kategori,
    String? gambarUrl,
    double? harga,
    int? stok,
    String? deskripsi,
    DateTime? createdAt,
  }) {
    return ProductModelFirebase(
      id: id ?? this.id,
      namaProduk: namaProduk ?? this.namaProduk,
      namaToko: namaToko ?? this.namaToko,
      kategori: kategori ?? this.kategori,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Membuat instance [ProductModelFirebase] dari Map / JSON Firestore.
  factory ProductModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFirebaseFromJson(json);

  /// Factory untuk membuat objek langsung dari [DocumentSnapshot] Firestore.
  factory ProductModelFirebase.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final mapWithId = Map<String, dynamic>.from(data)..['id'] = doc.id;
    return ProductModelFirebase.fromJson(mapWithId);
  }

  /// Helper factory untuk konversi Map generik.
  factory ProductModelFirebase.fromMap(Map<String, dynamic> map) =>
      ProductModelFirebase.fromJson(map);

  /// Mengonversi model ke Map JSON.
  Map<String, dynamic> toJson() => _$ProductModelFirebaseToJson(this);

  /// Mengonversi ke Map khusus penyimpanan dokumen Firestore (tanpa document ID).
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Alias untuk [toJson].
  Map<String, dynamic> toMap() => toJson();
}

/// Type aliases untuk fleksibilitas penamaan di seluruh project
typedef ProdukModelFirebase = ProductModelFirebase;
typedef ProductModel = ProductModelFirebase;
typedef ProdukModel = ProductModelFirebase;
