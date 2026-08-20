import 'dart:convert';

class KeranjangModel {
  final int? id;
  final int userId;
  final int produkId;
  final int jumlah;
  final String catatan;
  final String gambar;

  KeranjangModel({
    this.id,
    required this.userId,
    required this.produkId,
    required this.jumlah,
    required this.catatan,
    required this.gambar,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'produk_id': produkId,
      'jumlah': jumlah,
      'catatan': catatan,
      'gambar': gambar,
    };
  }

  factory KeranjangModel.fromMap(Map<String, dynamic> map) {
    return KeranjangModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: (map['user_id'] ?? 0) as int,
      produkId: (map['produk_id'] ?? 0) as int,
      jumlah: (map['jumlah'] ?? 0) as int,
      catatan: (map['catatan'] ?? '') as String,
      gambar: (map['gambar'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory KeranjangModel.fromJson(String source) =>
      KeranjangModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
