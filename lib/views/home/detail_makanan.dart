import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/model/favorit_model.dart';
import 'package:fodos/model/keranjang_model.dart';
import 'package:fodos/model/pesanan_aktif_model.dart';
import 'package:fodos/model/produk_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class DetailMakanan extends StatefulWidget {
  final ProdukModel produk;

  const DetailMakanan({super.key, required this.produk});

  @override
  State<DetailMakanan> createState() => _DetailMakananState();
}

class _DetailMakananState extends State<DetailMakanan> {
  int quantity = 1;
  bool isFavorite = false;
  int userId = 1; // Default fallback user ID

  @override
  void initState() {
    super.initState();
    _loadUserAndFavoriteStatus();
  }

  Future<void> _loadUserAndFavoriteStatus() async {
    final email = PreferenceHandler.getUserEmail();
    if (email != null) {
      final user = await DBHelper().getUserByEmail(email);
      if (user != null && user.id != null && mounted) {
        setState(() {
          userId = user.id!;
        });
      }
    }
    final favStatus = await DBHelper().isFavorit(userId, widget.produk.id ?? 0);
    if (!mounted) return;
    setState(() {
      isFavorite = favStatus;
    });
  }

  Future<void> _toggleFavorite() async {
    final produkId = widget.produk.id ?? 0;
    if (isFavorite) {
      await DBHelper().deleteFavorit(userId, produkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dihapus dari Favorit'), duration: Duration(seconds: 1)),
      );
    } else {
      await DBHelper().insertFavorit(FavoritModel(userId: userId, produkId: produkId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ditambahkan ke Favorit'), duration: Duration(seconds: 1)),
      );
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> _addToCart() async {
    final produkId = widget.produk.id ?? 0;
    final item = KeranjangModel(
      userId: userId,
      produkId: produkId,
      jumlah: quantity,
      catatan: 'Penyelamatan Surplus',
      gambar: widget.produk.gambar,
    );

    final success = await DBHelper().insertKeranjang(item);
    if (success) {
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
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to Home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memasukkan ke keranjang')));
      }
    }
  }

  Future<void> _pesanSekarang() async {
    final produkId = widget.produk.id ?? 0;
    final latestProduk = await DBHelper().getProdukById(produkId);
    final currentStok = latestProduk?.stok ?? widget.produk.stok;

    if (currentStok <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maaf, stok produk ini telah habis!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (quantity > currentStok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok tidak mencukupi! Sisa stok: $currentStok porsi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final double totalPrice = widget.produk.harga * quantity;

    final pesanan = PesananAktifModel(
      userId: userId,
      produkId: produkId,
      jumlah: quantity,
      totalHarga: totalPrice,
      tanggal: DateTime.now().toLocal().toString().substring(0, 16),
      status: 'Sedang Diproses',
      gambar: widget.produk.gambar,
    );

    final success = await DBHelper().insertPesananAktif(pesanan);
    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pesanan Berhasil'),
            content: Text(
              '${widget.produk.namaProduk} sebanyak $quantity porsi berhasil dipesan! Silakan cek status pesanan Anda di tab "Pesanan".',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Go back to Home with result
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuat pesanan')));
      }
    }
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
                  child: Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      image: DecorationImage(
                        image: widget.produk.gambar.startsWith('assets/')
                            ? AssetImage(widget.produk.gambar) as ImageProvider
                            : NetworkImage(widget.produk.gambar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                                const Icon(Icons.storefront, size: 16, color: AppColors.primary),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 20),

                      // Rating & Reviews Section
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
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '(124 ulasan)',
                                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer reviews list
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Ahmad Subarjo',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Makanannya masih sangat fresh! Rasanya enak banget dan porsinya masih bagus sekali. Worth it!',
                              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Siti Rahma',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                    Icon(Icons.star, color: Colors.grey, size: 12),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Penyelamatan yang sangat berharga! Hemat banget harganya untuk kualitas donat/makanan seperti ini.',
                              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),

                      // Spacing for Bottom Bar
                      const SizedBox(height: 100),
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
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
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
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
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

          // Sticky Bottom Action Bar (Quantity & Purchase)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: const Text(
                              'Ke Keranjang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              side: const BorderSide(color: AppColors.secondary, width: 1.5),
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
                            icon: const Icon(Icons.flash_on, size: 18),
                            label: const Text(
                              'Pesan Sekarang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          ),
        ],
      ),
    );
  }
}
