import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'firestrore_datetime.dart';

part 'order_model.g.dart';

/// Model item di dalam sebuah pesanan.
@JsonSerializable(explicitToJson: true)
class OrderItemModel {
  /// ID produk yang dipesan (merujuk ke Document ID `products`).
  @JsonKey(defaultValue: '')
  final String productId;

  /// Nama produk saat dipesan.
  @JsonKey(defaultValue: '')
  final String namaProduk;

  /// Nama toko/penjual produk.
  @JsonKey(defaultValue: '')
  final String namaToko;

  /// URL gambar produk.
  @JsonKey(defaultValue: '')
  final String gambarUrl;

  /// Harga satuan produk saat pesanan dibuat.
  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double harga;

  /// Jumlah kuantitas barang yang dipesan.
  @JsonKey(fromJson: intFromDynamic, defaultValue: 1)
  final int jumlah;

  /// Catatan pesanan khusus untuk item ini.
  @JsonKey(defaultValue: '')
  final String catatan;

  OrderItemModel({
    required this.productId,
    required this.namaProduk,
    this.namaToko = '',
    required this.gambarUrl,
    required this.harga,
    this.jumlah = 1,
    this.catatan = '',
  });

  /// Subtotal harga untuk item ini (harga satuan * jumlah).
  double get subtotal => harga * jumlah;

  /// Alias getter gambar untuk render UI
  String get gambar => gambarUrl;

  OrderItemModel copyWith({
    String? productId,
    String? namaProduk,
    String? namaToko,
    String? gambarUrl,
    double? harga,
    int? jumlah,
    String? catatan,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      namaProduk: namaProduk ?? this.namaProduk,
      namaToko: namaToko ?? this.namaToko,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      catatan: catatan ?? this.catatan,
    );
  }

  static Map<String, dynamic> _normalizeItemMap(Map<String, dynamic> raw) {
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(_normalizeItemMap(json));

  factory OrderItemModel.fromMap(Map<String, dynamic> map) =>
      OrderItemModel.fromJson(map);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  Map<String, dynamic> toMap() => toJson();
}

/// Model data untuk transaksi pesanan yang terhubung ke Firebase Firestore.
/// Cocok untuk koleksi `orders` atau `pesanan`.
@JsonSerializable(explicitToJson: true)
class OrderModelFirebase {
  /// Document ID transaksi pesanan di Firestore.
  @JsonKey(defaultValue: '')
  final String id;

  /// UID pengguna yang membuat pesanan.
  @JsonKey(defaultValue: '')
  final String userId;

  /// Nama lengkap pemesan.
  @JsonKey(defaultValue: '')
  final String userName;

  /// Nomor telepon pemesan.
  @JsonKey(defaultValue: '')
  final String userPhone;

  /// Alamat tujuan pengiriman pesanan.
  @JsonKey(defaultValue: '')
  final String alamatPengiriman;

  /// Daftar item produk yang dibeli.
  @JsonKey(defaultValue: [])
  final List<OrderItemModel> items;

  /// Total harga pesanan keseluruhan.
  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double totalHarga;

  /// Total jumlah item produk.
  @JsonKey(fromJson: intFromDynamic, defaultValue: 0)
  final int totalItem;

  /// Biaya ongkos kirim.
  @JsonKey(fromJson: doubleFromDynamic, defaultValue: 0.0)
  final double ongkir;

  /// Metode pembayaran (misal: "COD", "Transfer Bank", "E-Wallet", "Tunai").
  @JsonKey(defaultValue: 'Tunai')
  final String metodePembayaran;

  /// Status pemesanan (contoh: "Menunggu Konfirmasi", "Diproses", "Dikirim", "Selesai", "Dibatalkan").
  @JsonKey(defaultValue: 'Diproses')
  final String status;

  /// Catatan umum pemesanan.
  @JsonKey(defaultValue: '')
  final String catatan;

  /// Waktu pembuatan pesanan.
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;

  /// Waktu update status terakhir.
  @JsonKey(fromJson: dateTimeFromJsonNullable, toJson: dateTimeToJson)
  final DateTime? updatedAt;

  OrderModelFirebase({
    this.id = '',
    required this.userId,
    this.userName = '',
    this.userPhone = '',
    this.alamatPengiriman = '',
    required this.items,
    required this.totalHarga,
    int? totalItem,
    this.ongkir = 0.0,
    this.metodePembayaran = 'Tunai',
    this.status = 'Diproses',
    this.catatan = '',
    DateTime? createdAt,
    this.updatedAt,
  })  : totalItem = totalItem ?? items.fold(0, (total, item) => total + item.jumlah),
        createdAt = createdAt ?? DateTime.now();

  /// Memeriksa apakah pesanan masih berstatus aktif (belum selesai / dibatalkan).
  bool get isAktif => status != 'Selesai' && status != 'Dibatalkan';

  /// Memeriksa apakah pesanan sudah selesai.
  bool get isSelesai => status == 'Selesai';

  /// Memeriksa apakah pesanan dibatalkan.
  bool get isDibatalkan => status == 'Dibatalkan';

  OrderModelFirebase copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? alamatPengiriman,
    List<OrderItemModel>? items,
    double? totalHarga,
    int? totalItem,
    double? ongkir,
    String? metodePembayaran,
    String? status,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModelFirebase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      alamatPengiriman: alamatPengiriman ?? this.alamatPengiriman,
      items: items ?? this.items,
      totalHarga: totalHarga ?? this.totalHarga,
      totalItem: totalItem ?? this.totalItem,
      ongkir: ongkir ?? this.ongkir,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Membuat instance [OrderModelFirebase] dari Map / JSON Firestore.
  factory OrderModelFirebase.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFirebaseFromJson(json);

  /// Factory untuk membuat instance langsung dari [DocumentSnapshot] Firestore.
  factory OrderModelFirebase.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final mapWithId = Map<String, dynamic>.from(data)..['id'] = doc.id;
    return OrderModelFirebase.fromJson(mapWithId);
  }

  /// Helper factory untuk konversi Map generik.
  factory OrderModelFirebase.fromMap(Map<String, dynamic> map) =>
      OrderModelFirebase.fromJson(map);

  /// Mengonversi model ke Map JSON.
  Map<String, dynamic> toJson() => _$OrderModelFirebaseToJson(this);

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
typedef PesananModelFirebase = OrderModelFirebase;
typedef OrderModel = OrderModelFirebase;
typedef PesananModel = OrderModelFirebase;
typedef ItemPesananModel = OrderItemModel;
