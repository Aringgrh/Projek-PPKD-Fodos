import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_images.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/product_model.dart';
import 'package:fodos/widgets/widget_method.dart';

class HalamanTambahProdukFodos extends StatefulWidget {
  const HalamanTambahProdukFodos({super.key});

  @override
  State<HalamanTambahProdukFodos> createState() =>
      _HalamanTambahProdukFodosState();
}

class _HalamanTambahProdukFodosState extends State<HalamanTambahProdukFodos> {
  bool isLoading = false;

  // Controller untuk Produk
  final TextEditingController namaProdukC = TextEditingController();
  final TextEditingController namaTokoC = TextEditingController();
  final TextEditingController alamatTokoC = TextEditingController();
  final TextEditingController hargaC = TextEditingController();
  final TextEditingController stokC = TextEditingController();
  final TextEditingController kategoriC = TextEditingController();
  final TextEditingController gambarC = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    namaProdukC.dispose();
    namaTokoC.dispose();
    alamatTokoC.dispose();
    hargaC.dispose();
    stokC.dispose();
    kategoriC.dispose();
    gambarC.dispose();
    super.dispose();
  }

  Future<void> simpanProduk() async {
    // 1. Validasi Input Form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 2. Buat objek ProductModel dari controller
      final produkBaru = ProductModel(
        namaProduk: namaProdukC.text.trim(),
        namaToko: namaTokoC.text.trim(),
        alamatToko: alamatTokoC.text.trim(),
        harga: double.parse(hargaC.text.trim()),
        stok: int.parse(stokC.text.trim()),
        kategori: kategoriC.text.trim(),
        gambarUrl: gambarC.text.trim(),
        createdAt: DateTime.now(),
      );

      // 3. Simpan ke koleksi 'products' di Firebase Firestore menggunakan toJson()
      await FirebaseFirestore.instance
          .collection('products')
          .add(produkBaru.toJson());

      if (!mounted) return;

      // 4. Notifikasi Berhasil & Reset / Pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil disimpan ke Firebase!'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya jika dipanggil via Push
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // Atau bersihkan form jika tetap di halaman yang sama
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan produk: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Produk"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Logo/Header Image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(75),
                        ),
                        child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Input Produk Baru",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 20),

                  // 1. Nama Produk
                  judulTextfield("Nama Produk"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nama Produk",
                    kontroller: namaProdukC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama Produk Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Nama Toko
                  judulTextfield("Nama Toko"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nama Toko",
                    kontroller: namaTokoC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama Toko Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2b. Alamat Toko
                  judulTextfield("Alamat Toko"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Alamat Lengkap Toko",
                    kontroller: alamatTokoC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Alamat Toko Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Harga Produk
                  judulTextfield("Harga Produk (Rp)"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Harga Produk",
                    kontroller: hargaC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Harga Wajib Diisi";
                      }
                      if (int.tryParse(value) == null) {
                        return "Harga Harus Berupa Angka";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Stok Produk
                  judulTextfield("Stok Produk"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Jumlah Stok",
                    kontroller: stokC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Stok Wajib Diisi";
                      }
                      if (int.tryParse(value) == null) {
                        return "Stok Harus Berupa Angka";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Kategori Produk
                  judulTextfield("Kategori"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Kategori Produk (Contoh: Makanan, Minuman)",
                    kontroller: kategoriC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Kategori Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 6. URL Gambar Produk
                  judulTextfield("URL Gambar Produk"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Link/URL Gambar Produk",
                    kontroller: gambarC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "URL Gambar Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : simpanProduk,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Simpan Produk",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
