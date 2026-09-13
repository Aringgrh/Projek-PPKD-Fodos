import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/detail_makanan.dart';
import 'package:fodos/views/home/halaman_favorit.dart';
import 'package:fodos/views/home/halaman_keranjang.dart';
import 'package:fodos/views/home/halaman_pilih_lokasi.dart';
import 'package:fodos/widgets/widget_carousel.dart';
import 'package:fodos/widgets/widget_display_produk.dart';
import 'package:fodos/widgets/widget_home.dart';

class HomeFodos extends StatefulWidget {
  const HomeFodos({super.key});

  @override
  State<HomeFodos> createState() => _HomeFodosState();
}

class _HomeFodosState extends State<HomeFodos> {
  int selectedCategoryIndex = 0;
  String _selectedLocationTitle = 'Pilih Lokasi Anda';
  String _selectedLocationSubtitle = 'Sekitar kamu';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    String title = PreferenceHandler.getSelectedLocation();
    String detail = PreferenceHandler.getSelectedLocationDetail();

    if (user != null) {
      if (title == "Pilih Lokasi Anda" || title == "Jl. Sudirman No. 45") {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final firestoreAlamat = data['alamat'] as String?;
            final firestoreDetail = data['alamatDetail'] as String?;

            if (firestoreAlamat != null && firestoreAlamat.trim().isNotEmpty) {
              title = firestoreAlamat.trim();
              detail = firestoreDetail?.trim().isNotEmpty == true
                  ? firestoreDetail!.trim()
                  : 'Sekitar kamu';
              await PreferenceHandler.setSelectedLocation(
                title,
                detail: detail,
              );
            }
          }
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedLocationTitle = title;
      _selectedLocationSubtitle = detail;
    });
  }

  final List<Map<String, dynamic>> categories = [
    {"name": "Semua", "icon": Icons.menu_book_outlined},
    {"name": "Roti", "icon": Icons.bakery_dining},
    {"name": "Makanan Berat", "icon": Icons.restaurant},
  ];

  Stream<List<ProductModel>> _streamProduk() {
    final collection = FirebaseFirestore.instance.collection('products');
    Query<Map<String, dynamic>> query = collection;

    if (selectedCategoryIndex == 1) {
      query = query.where('kategori', isEqualTo: 'Roti');
    } else if (selectedCategoryIndex == 2) {
      query = query.where('kategori', isEqualTo: 'Makanan Berat');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Top App Bar / Location Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Info
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HalamanPilihLokasi(),
                            ),
                          );
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              _selectedLocationTitle =
                                  result['title'] ?? _selectedLocationTitle;
                              _selectedLocationSubtitle =
                                  result['detail'] ?? _selectedLocationSubtitle;
                            });
                          } else {
                            _loadLocation();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _selectedLocationTitle,
                                    style: AppTextstyle.heading1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textGrey,
                                  size: 20,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                _selectedLocationSubtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Header Action Buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanFavorit(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.favorite_border,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Favorit Saya',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanKeranjang(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Keranjang',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Hero Banner Slider
              carouselGambar(),

              // Category Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text("Kategori", style: AppTextstyle.sectionTitle),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return pilihanKategori(
                      icon: cat["icon"],
                      text: cat["name"],
                      isSelected: selectedCategoryIndex == index,
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Product Section Header ("Paling Diminati di Sekitarmu")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Paling Diminati di Sekitarmu",
                        style: AppTextstyle.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "LIHAT SEMUA",
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Product Display Cards with StreamBuilder from Firestore
              StreamBuilder<List<ProductModel>>(
                stream: _streamProduk(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Gagal memuat produk: ${snapshot.error}'),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 64,
                              color: AppColors.textGrey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada produk untuk kategori ini.',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final listProduk = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listProduk.length,
                    itemBuilder: (context, index) {
                      final produk = listProduk[index];
                      return displayProduk(
                        image: produk.gambarUrl,
                        namaMakanan: produk.namaProduk,
                        namaToko: produk.namaToko,
                        sisaPorsi: produk.stok.toString(),
                        alamat: produk.alamatToko.isNotEmpty
                            ? produk.alamatToko
                            : 'Alamat toko belum diatur',
                        harga:
                            "Rp ${produk.harga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailMakanan(produk: produk),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
