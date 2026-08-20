import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class UserModelLoginSQL {
  final int? id;
  final String nama;
  final String nomorhp;
  final String email;
  final String password;
  final String alamat;
  final String? gambar;

  UserModelLoginSQL({
    this.id,
    required this.nama,
    required this.nomorhp,
    required this.email,
    required this.password,
    required this.alamat,
    this.gambar,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'nomorhp': nomorhp,
      'email': email,
      'password': password,
      'alamat': alamat,
      'gambar': gambar,
    };
  }

  factory UserModelLoginSQL.fromMap(Map<String, dynamic> map) {
    return UserModelLoginSQL(
      id: map['id'] != null ? map['id'] as int : null,
      nama: (map['nama'] ?? '') as String,
      nomorhp: (map['nomorhp'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      password: (map['password'] ?? '') as String,
      alamat: (map['alamat'] ?? '') as String,
      gambar: map['gambar'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelLoginSQL.fromJson(String source) =>
      UserModelLoginSQL.fromMap(json.decode(source) as Map<String, dynamic>);
}
