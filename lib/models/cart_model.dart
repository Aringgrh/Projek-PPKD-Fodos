import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'firestrore_datetime.dart';

part 'cart_model.g.dart';

/// Model data untuk item keranjang belanja yang terhubung ke Firebase Firestore.
/// Cocok untuk koleksi `carts` atau subkoleksi `users/{userId}/cart`.
@JsonSerializable(explicitToJson: true)
class CartModelFirebase {
  /// Document ID di Firestore.
  @JsonKey(defaultValue: '')
  final String id;

  /// UID pengguna pemilik keranjang.
  @JsonKey(defaultValue: '')
  final String userId;

  /// ID produk yang dimasukkan ke keranjang (merujuk ke Document ID `products`).
  @JsonKey(defaultValue: '')
  final String productId;

  /// Nama produk.
  @JsonKey(defaultValue: '')
  final String namaProduk;

  /// Nama toko/penjual.
  @JsonKey(defaultValue: '')
  final String namaToko;

  /// URL gambar produk.
  @JsonKey(defaultValue: '')
  final String gambarUrl;

  /// Harga satuan produk.
  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double harga;

  /// Jumlah kuantitas barang yang dipesan.
  @JsonKey(fromJson: intFromDynamic, defaultValue: 1)
  final int jumlah;

  /// Catatan pesanan khusus dari pembeli (contoh: "Pedas sedang, tanpa bawang").
  @JsonKey(defaultValue: '')
  final String catatan;

  /// Waktu item dimasukkan ke keranjang.
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;

  /// Waktu item terakhir diperbarui.
  @JsonKey(fromJson: dateTimeFromJsonNullable, toJson: dateTimeToJson)
  final DateTime? updatedAt;

  CartModelFirebase({
    this.id = '',
    required this.userId,
    required this.productId,
    required this.namaProduk,
    this.namaToko = '',
    required this.gambarUrl,
    required this.harga,
    this.jumlah = 1,
    this.catatan = '',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Menghitung total harga untuk item ini (harga satuan * jumlah kuantitas).
  double get subtotal => harga * jumlah;

  /// Alias getter gambar untuk render UI
  String get gambar => gambarUrl;

  /// Alias getter produkId untuk kompatibilitas
  String get produkId => productId;

  CartModelFirebase copyWith({
    String? id,
    String? userId,
    String? productId,
    String? namaProduk,
    String? namaToko,
    String? gambarUrl,
    double? harga,
    int? jumlah,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModelFirebase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      namaProduk: namaProduk ?? this.namaProduk,
      namaToko: namaToko ?? this.namaToko,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Normalisasi Map data Firestore
  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

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

    final currentNama = (map['namaProduk'] ?? '').toString().trim();
    if (currentNama.isEmpty) {
      final fallbackNama =
          map['nama_produk'] ?? map['nama'] ?? map['name'] ?? map['title'];
      if (fallbackNama != null) {
        map['namaProduk'] = fallbackNama.toString().trim();
      }
    }

    final currentToko = (map['namaToko'] ?? '').toString().trim();
    if (currentToko.isEmpty) {
      final fallbackToko =
          map['nama_toko'] ?? map['toko'] ?? map['store'] ?? map['shop'];
      if (fallbackToko != null) {
        map['namaToko'] = fallbackToko.toString().trim();
      }
    }

    return map;
  }

  /// Membuat instance [CartModelFirebase] dari Map / JSON Firestore.
  factory CartModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$CartModelFirebaseFromJson(_normalizeMap(json));

  /// Factory untuk membuat instance langsung dari [DocumentSnapshot] Firestore.
  factory CartModelFirebase.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final mapWithId = Map<String, dynamic>.from(data)..['id'] = doc.id;
    return CartModelFirebase.fromJson(mapWithId);
  }

  /// Helper factory untuk konversi Map generik.
  factory CartModelFirebase.fromMap(Map<String, dynamic> map) =>
      CartModelFirebase.fromJson(map);

  /// Mengonversi model ke Map JSON.
  Map<String, dynamic> toJson() => _$CartModelFirebaseToJson(this);

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
typedef KeranjangModelFirebase = CartModelFirebase;
typedef CartModel = CartModelFirebase;
typedef KeranjangModel = CartModelFirebase;
typedef CartItemModel = CartModelFirebase;
