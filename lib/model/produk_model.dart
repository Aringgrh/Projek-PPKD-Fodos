import 'dart:convert';

class ProdukModel {
  final int? id;
  final String namaProduk;
  final String namaToko;
  final double harga;
  final int stok;
  final String kategori;
  final String gambar;

  ProdukModel({
    this.id,
    required this.namaProduk,
    required this.namaToko,
    required this.harga,
    required this.stok,
    required this.kategori,
    required this.gambar,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nama_produk': namaProduk,
      'nama_toko': namaToko,
      'harga': harga,
      'stok': stok,
      'kategori': kategori,
      'gambar': gambar,
    };
  }

  factory ProdukModel.fromMap(Map<String, dynamic> map) {
    return ProdukModel(
      id: map['id'] != null ? map['id'] as int : null,
      namaProduk: (map['nama_produk'] ?? '') as String,
      namaToko: (map['nama_toko'] ?? '') as String,
      harga: (map['harga'] ?? 0.0) is int 
          ? (map['harga'] as int).toDouble() 
          : (map['harga'] ?? 0.0) as double,
      stok: (map['stok'] ?? 0) as int,
      kategori: (map['kategori'] ?? '') as String,
      gambar: (map['gambar'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProdukModel.fromJson(String source) =>
      ProdukModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
