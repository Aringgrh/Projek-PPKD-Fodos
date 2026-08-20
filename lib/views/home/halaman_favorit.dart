import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/model/produk_model.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/detail_makanan.dart';

class HalamanFavorit extends StatefulWidget {
  const HalamanFavorit({super.key});

  @override
  State<HalamanFavorit> createState() => _HalamanFavoritState();
}

class _HalamanFavoritState extends State<HalamanFavorit> {
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await PreferenceHandler.getUserEmail();
    if (email != null) {
      final user = await DBHelper().getUserByEmail(email);
      if (user != null && user.id != null) {
        setState(() {
          userId = user.id!;
        });
      }
    }
  }

  Future<void> _removeFavorite(int produkId) async {
    await DBHelper().deleteFavorit(userId, produkId);
    setState(() {}); // Refresh list
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari Favorit'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Favorit Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<ProdukModel>>(
        future: DBHelper().getFavoritProductsByUserId(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada makanan favorit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sukai makanan surplus pilihanmu untuk disimpan di sini.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final favoritedList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: favoritedList.length,
            itemBuilder: (context, index) {
              final produk = favoritedList[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailMakanan(produk: produk),
                        ),
                      );
                      setState(() {}); // Refresh list upon returning
                    },
                    child: Row(
                      children: [
                        // Image Container
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: produk.gambar.startsWith('assets/')
                                ? Image.asset(produk.gambar, fit: BoxFit.cover)
                                : Image.network(produk.gambar, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, Shop & Price
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produk.namaProduk,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  produk.namaToko,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Rp ${produk.harga.toInt().toString().replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]}.',
                                      )}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Remove Favorite Button
                        IconButton(
                          onPressed: () => _removeFavorite(produk.id ?? 0),
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          tooltip: 'Hapus dari Favorit',
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
