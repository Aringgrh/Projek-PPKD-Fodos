import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/halaman_pembayaran.dart';
import 'package:fodos/widgets/app_image_loader.dart';

class HalamanKeranjang extends StatefulWidget {
  const HalamanKeranjang({super.key});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  String userId = '';
  Set<String> selectedCartIds = {};
  bool _isInitialized = false;

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

  Stream<List<CartModel>> _streamCart() {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => CartModel.fromFirestore(doc)).toList(),
        );
  }

  double _calculateTotal(List<CartModel> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      if (selectedCartIds.contains(item.id)) {
        total += item.subtotal;
      }
    }
    return total;
  }

  Future<void> _updateQuantity(String cartId, int newQuantity) async {
    if (newQuantity <= 0) return;
    try {
      await FirebaseFirestore.instance.collection('carts').doc(cartId).update({
        'jumlah': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengubah jumlah: $e')));
      }
    }
  }

  Future<void> _deleteCartItem(String cartId) async {
    try {
      await FirebaseFirestore.instance.collection('carts').doc(cartId).delete();
      setState(() {
        selectedCartIds.remove(cartId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus item: $e')));
      }
    }
  }

  void _checkout(List<CartModel> cartItems) {
    final selectedItems = cartItems
        .where((item) => selectedCartIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu produk untuk dipesan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final orderItems = selectedItems
        .map(
          (item) => OrderItemModel(
            productId: item.productId,
            namaProduk: item.namaProduk,
            namaToko: item.namaToko,
            gambarUrl: item.gambarUrl,
            harga: item.harga,
            jumlah: item.jumlah,
            catatan: item.catatan,
          ),
        )
        .toList();

    final cartDocIds = selectedItems
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toList();

    context.push(
      HalamanPembayaran(
        items: orderItems,
        namaToko: orderItems.first.namaToko,
        isFromCart: true,
        cartItemDocIds: cartDocIds,
      ),
    );
  }

  Widget _buildItemImage(String image) {
    return AppImageLoader(
      imageUrl: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Keranjang Penyelamatan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<CartModel>>(
        stream: _streamCart(),
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
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keranjang kamu masih kosong',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada makanan surplus yang ditambahkan.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;

          // Initialize selection: Select all items by default on first load
          if (!_isInitialized) {
            selectedCartIds = cartItems.map((item) => item.id).toSet();
            _isInitialized = true;
          }

          final totalCartPrice = _calculateTotal(cartItems);

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final bool isSelected = selectedCartIds.contains(item.id);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Checkbox for selection
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                selectedCartIds.add(item.id);
                              } else {
                                selectedCartIds.remove(item.id);
                              }
                            });
                          },
                        ),

                        // Image Container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: _buildItemImage(item.gambarUrl),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title, Shop & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduk,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.namaToko.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.namaToko,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                "Rp ${item.harga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity controls and Delete button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _deleteCartItem(item.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.grey,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (item.jumlah > 1) {
                                      _updateQuantity(item.id, item.jumlah - 1);
                                    } else {
                                      _deleteCartItem(item.id);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    '${item.jumlah}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      _updateQuantity(item.id, item.jumlah + 1),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  );
                },
              ),

              // Bottom Total & Checkout Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Rp ${totalCartPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _checkout(cartItems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Pesan Sekarang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
