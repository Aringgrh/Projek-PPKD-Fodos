import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/detail_makanan.dart';

class HalamanFavorit extends StatefulWidget {
  const HalamanFavorit({super.key});

  @override
  State<HalamanFavorit> createState() => _HalamanFavoritState();
}

class _HalamanFavoritState extends State<HalamanFavorit> {
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    final uid =
        currentFirebaseUser?.uid ??
        (PreferenceHandler.getUserEmail() ?? 'guest');
    setState(() {
      userId = uid;
    });
  }

  Stream<List<FavoriteModel>> _streamFavorites() {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FavoriteModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> _removeFavorite(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari Favorit'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus favorit: $e')));
      }
    }
  }

  Widget _buildItemImage(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.fastfood, color: Colors.grey),
        ),
      );
    } else if (image.isNotEmpty) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.fastfood, color: Colors.grey),
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Favorit Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<FavoriteModel>>(
        stream: _streamFavorites(),
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
              final fav = favoritedList[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
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
                      // Fetch actual product details if exists
                      ProductModel product;
                      if (fav.productId.isNotEmpty) {
                        try {
                          final doc = await FirebaseFirestore.instance
                              .collection('products')
                              .doc(fav.productId)
                              .get();
                          if (doc.exists) {
                            product = ProductModel.fromFirestore(doc);
                          } else {
                            product = ProductModel(
                              id: fav.productId,
                              namaProduk: fav.namaProduk,
                              namaToko: fav.namaToko,
                              kategori: fav.kategori,
                              gambarUrl: fav.gambarUrl,
                              harga: fav.harga,
                              stok: 1,
                            );
                          }
                        } catch (_) {
                          product = ProductModel(
                            id: fav.productId,
                            namaProduk: fav.namaProduk,
                            namaToko: fav.namaToko,
                            kategori: fav.kategori,
                            gambarUrl: fav.gambarUrl,
                            harga: fav.harga,
                            stok: 1,
                          );
                        }
                      } else {
                        product = ProductModel(
                          id: fav.productId,
                          namaProduk: fav.namaProduk,
                          namaToko: fav.namaToko,
                          kategori: fav.kategori,
                          gambarUrl: fav.gambarUrl,
                          harga: fav.harga,
                          stok: 1,
                        );
                      }

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailMakanan(produk: product),
                          ),
                        );
                      }
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
                            child: _buildItemImage(fav.gambarUrl),
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
                                  fav.namaProduk,
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
                                  fav.namaToko,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Rp ${fav.harga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
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
                          onPressed: () => _removeFavorite(fav.id),
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
