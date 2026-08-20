import 'dart:convert';

class RiwayatModel {
  final int? id;
  final int userId;
  final int produkId;
  final int jumlah;
  final double totalHarga;
  final String tanggal;
  final String status;
  final String gambar;

  RiwayatModel({
    this.id,
    required this.userId,
    required this.produkId,
    required this.jumlah,
    required this.totalHarga,
    required this.tanggal,
    required this.status,
    required this.gambar,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'produk_id': produkId,
      'jumlah': jumlah,
      'total_harga': totalHarga,
      'tanggal': tanggal,
      'status': status,
      'gambar': gambar,
    };
  }

  factory RiwayatModel.fromMap(Map<String, dynamic> map) {
    return RiwayatModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: (map['user_id'] ?? 0) as int,
      produkId: (map['produk_id'] ?? 0) as int,
      jumlah: (map['jumlah'] ?? 0) as int,
      totalHarga: (map['total_harga'] ?? 0.0) is int
          ? (map['total_harga'] as int).toDouble()
          : (map['total_harga'] ?? 0.0) as double,
      tanggal: (map['tanggal'] ?? '') as String,
      status: (map['status'] ?? '') as String,
      gambar: (map['gambar'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RiwayatModel.fromJson(String source) =>
      RiwayatModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
