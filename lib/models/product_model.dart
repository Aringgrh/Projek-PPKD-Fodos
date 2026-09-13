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

  /// Alamat lokasi toko/warung penjual.
  @JsonKey(defaultValue: '')
  final String alamatToko;

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
    this.alamatToko = '',
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
    String? alamatToko,
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
      alamatToko: alamatToko ?? this.alamatToko,
      kategori: kategori ?? this.kategori,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Normalisasi Map data dari Firestore untuk menangani variasi penamaan field (misal: 'gambar', 'imageUrl', 'image')
  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

    // Normalisasi Gambar / URL
    final currentGambar = (map['gambarUrl'] ?? '').toString().trim();
    if (currentGambar.isEmpty) {
      final fallback = map['gambar'] ??
          map['imageUrl'] ??
          map['image'] ??
          map['foto'] ??
          map['fotoUrl'] ??
          map['photoUrl'] ??
          map['img'];
      if (fallback != null) {
        map['gambarUrl'] = fallback.toString().trim();
      }
    }

    // Normalisasi Nama Produk
    final currentNama = (map['namaProduk'] ?? '').toString().trim();
    if (currentNama.isEmpty) {
      final fallbackNama =
          map['nama_produk'] ?? map['nama'] ?? map['name'] ?? map['title'];
      if (fallbackNama != null) {
        map['namaProduk'] = fallbackNama.toString().trim();
      }
    }

    // Normalisasi Nama Toko
    final currentToko = (map['namaToko'] ?? '').toString().trim();
    if (currentToko.isEmpty) {
      final fallbackToko =
          map['nama_toko'] ?? map['toko'] ?? map['store'] ?? map['shop'];
      if (fallbackToko != null) {
        map['namaToko'] = fallbackToko.toString().trim();
      }
    }

    // Normalisasi Alamat Toko langsung dari Firebase Firestore
    final currentAlamat = (map['alamatToko'] ?? '').toString().trim();
    if (currentAlamat.isEmpty) {
      final fallbackAlamat = map['alamat_toko'] ??
          map['alamat'] ??
          map['address'] ??
          map['lokasiToko'] ??
          map['lokasi'];
      if (fallbackAlamat != null) {
        map['alamatToko'] = fallbackAlamat.toString().trim();
      }
    }

    return map;
  }

  /// Membuat instance [ProductModelFirebase] dari Map / JSON Firestore.
  factory ProductModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFirebaseFromJson(_normalizeMap(json));

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

  /// Mengonversi model ke Map JSON (Aman untuk SharedPreferences).
  Map<String, dynamic> toJson() {
    final map = _$ProductModelFirebaseToJson(this);
    // Ubah Timestamp menjadi string ISO8601 agar aman saat di-encode JSON
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    } else if (map['createdAt'] is DateTime) {
      map['createdAt'] = (map['createdAt'] as DateTime).toIso8601String();
    }
    return map;
  }

  /// Mengonversi ke Map khusus penyimpanan dokumen Firestore (tanpa document ID).
  Map<String, dynamic> toFirestore() {
    final map = _$ProductModelFirebaseToJson(this);
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
