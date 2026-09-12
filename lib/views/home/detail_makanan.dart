import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/halaman_pembayaran.dart';
import 'package:fodos/widgets/app_image_loader.dart';

class DetailMakanan extends StatefulWidget {
  final ProductModel produk;

  const DetailMakanan({super.key, required this.produk});

  @override
  State<DetailMakanan> createState() => _DetailMakananState();
}

class _DetailMakananState extends State<DetailMakanan> {
  int quantity = 1;
  bool isFavorite = false;
  String userId = '';
  bool showAllReviews = false;


  Future<void> _bukaRuteNavigasi() async {
    final String storeAddress = widget.produk.alamatToko.isNotEmpty
        ? widget.produk.alamatToko
        : '${widget.produk.namaToko}, Jakarta, Indonesia';

    final String destination = Uri.encodeComponent(storeAddress);
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi Peta / Google Maps.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka rute navigasi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndFavoriteStatus();
  }

  Future<void> _loadUserAndFavoriteStatus() async {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    final uid =
        currentFirebaseUser?.uid ??
        (PreferenceHandler.getUserEmail() ?? 'guest');
    if (mounted) {
      setState(() {
        userId = uid;
      });
    }

    if (widget.produk.id.isNotEmpty) {
      try {
        final favQuery = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .where('productId', isEqualTo: widget.produk.id)
            .limit(1)
            .get();

        if (mounted) {
          setState(() {
            isFavorite = favQuery.docs.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('Error checking favorite status: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final favRef = FirebaseFirestore.instance.collection('favorites');
    try {
      if (isFavorite) {
        final query = await favRef
            .where('userId', isEqualTo: userId)
            .where('productId', isEqualTo: widget.produk.id)
            .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari Favorit'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        final fav = FavoriteModel(
          userId: userId,
          productId: widget.produk.id,
          namaProduk: widget.produk.namaProduk,
          namaToko: widget.produk.namaToko,
          kategori: widget.produk.kategori,
          gambarUrl: widget.produk.gambarUrl,
          harga: widget.produk.harga,
        );
        await favRef.add(fav.toFirestore());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ditambahkan ke Favorit'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal update favorit: $e')));
      }
    }
  }

  Future<void> _addToCart() async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('carts');
      final existing = await cartRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: widget.produk.id)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentJumlah = doc.data()['jumlah'] as int? ?? 1;
        await doc.reference.update({
          'jumlah': currentJumlah + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final item = CartModel(
          userId: userId,
          productId: widget.produk.id,
          namaProduk: widget.produk.namaProduk,
          namaToko: widget.produk.namaToko,
          gambarUrl: widget.produk.gambarUrl,
          harga: widget.produk.harga,
          jumlah: quantity,
          catatan: 'Penyelamatan Surplus',
        );
        await cartRef.add(item.toFirestore());
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Berhasil'),
            content: Text(
              '${widget.produk.namaProduk} sebanyak $quantity porsi berhasil dimasukkan ke keranjang.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memasukkan ke keranjang: $e')),
        );
      }
    }
  }

  void _pesanSekarang() {
    final item = OrderItemModel(
      productId: widget.produk.id,
      namaProduk: widget.produk.namaProduk,
      namaToko: widget.produk.namaToko,
      gambarUrl: widget.produk.gambarUrl,
      harga: widget.produk.harga,
      jumlah: quantity,
      catatan: 'Penyelamatan Surplus',
    );

    context.push(
      HalamanPembayaran(
        items: [item],
        namaToko: widget.produk.namaToko,
        isFromCart: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double rawPrice = widget.produk.harga;
    final double totalPrice = rawPrice * quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Cover
                Hero(
                  tag: 'produk_image_${widget.produk.id}',
                  child: SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: AppImageLoader(
                      imageUrl: widget.produk.gambar,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Name & Category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.produk.namaToko,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.produk.kategori.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Product Title
                      Text(
                        widget.produk.namaProduk,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price & Stock Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rp ${rawPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.produk.stok} porsi tersisa',
                              style: const TextStyle(
                                color: AppColors.badgeText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 20),

                      // Description: Tentang Penyelamatan Ini
                      const Text(
                        'Tentang Penyelamatan Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dapatkan porsi makanan lezat dan berkualitas tinggi dari ${widget.produk.namaToko}. Dengan menyelamatkan ${widget.produk.namaProduk} ini, kamu turut berpartisipasi aktif dalam menekan tingkat pemborosan makanan (food waste) dan mendukung kelestarian bumi kita!',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textGrey,
                        ),
                      ),

                      // Store Address & Direction Card Section
                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 20),

                      const Text(
                        'Lokasi & Alamat Toko',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.produk.namaToko,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: AppColors.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.produk.alamatToko.isNotEmpty
                                                  ? widget.produk.alamatToko
                                                  : 'Alamat toko belum diatur',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textGrey,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _bukaRuteNavigasi,
                                icon: const Icon(Icons.directions_rounded, size: 18),
                                label: const Text(
                                  'Petunjuk Arah / Rute Navigasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 20),

                      // Rating & Reviews Section (Dynamic from Firestore reviews collection)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('productId', isEqualTo: widget.produk.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          List<ReviewModel> reviews = [];
                          if (snapshot.hasData) {
                            reviews = snapshot.data!.docs
                                .map((doc) => ReviewModel.fromFirestore(
                                      doc as DocumentSnapshot<Map<String, dynamic>>,
                                    ))
                                .toList()
                              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                          }

                          final double avgRating = reviews.isNotEmpty
                              ? (reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                                  reviews.length)
                              : 0.0;
                          final String avgRatingStr = reviews.isNotEmpty
                              ? avgRating.toStringAsFixed(1)
                              : 'Belum ada';
                          final String countStr = '(${reviews.length} ulasan)';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Rating & Ulasan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        avgRatingStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        countStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Customer reviews list
                              if (reviews.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: const [
                                      Icon(
                                        Icons.rate_review_outlined,
                                        size: 36,
                                        color: AppColors.textGrey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Belum ada ulasan untuk produk ini',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Beli & selesaikan pesanan produk ini untuk memberikan ulasan pertama!',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGrey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: showAllReviews
                                      ? reviews.length
                                      : reviews.take(3).length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final review = reviews[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  review.userName.isNotEmpty
                                                      ? review.userName
                                                      : 'Pengguna Fodos',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: AppColors.textDark,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(5, (
                                                  starIdx,
                                                ) {
                                                  return Icon(
                                                    starIdx <
                                                            review.rating.round()
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_outline_rounded,
                                                    color: starIdx <
                                                            review.rating.round()
                                                        ? Colors.amber
                                                        : Colors.grey[300],
                                                    size: 14,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          if (review.ulasan.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              review.ulasan,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            review.createdAt
                                                .toLocal()
                                                .toString()
                                                .substring(0, 10),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (reviews.length > 3) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          showAllReviews = !showAllReviews;
                                        });
                                      },
                                      icon: Icon(
                                        showAllReviews
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      label: Text(
                                        showAllReviews
                                            ? 'Tampilkan Lebih Sedikit'
                                            : 'Lihat Semua Ulasan (${reviews.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                            ],
                          );
                        },
                      ),


                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Custom App Bar (Back & Favorite Buttons)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                  ),
                ),

                // Favorite Button
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : AppColors.textDark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Quantity Control & Total Price Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity Control
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove, size: 16),
                          color: AppColors.primary,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (quantity < widget.produk.stok) {
                              setState(() {
                                quantity++;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stok porsi terbatas!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  // Total Price display
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Total: Rp ${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Action Buttons
              Row(
                children: [
                  // "Tambah ke Keranjang" Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Ke Keranjang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(
                          color: AppColors.secondary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // "Pesan Sekarang" Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pesanSekarang,
                      label: const Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
