import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/widgets/app_image_loader.dart';

class RiwayatView extends StatelessWidget {
  final String userId;
  const RiwayatView({super.key, required this.userId});

  Stream<List<OrderModel>> _streamHistoryOrders() {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .where((order) => !order.isAktif)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
  }

  Widget _buildItemImage(String image) {
    return AppImageLoader(
      imageUrl: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Future<void> _tampilkanDialogUlasan(
    BuildContext context,
    OrderModel order,
  ) async {
    double selectedRating = 5.0;
    final TextEditingController ulasanController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beri Penilaian & Ulasan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bagaimana pengalaman penyelamatan makanan Anda?',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Star Rating Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          iconSize: 32,
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = starValue.toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    Text(
                      '${selectedRating.toInt()} dari 5 Bintang',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Review input field
                    TextField(
                      controller: ulasanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Tulis ulasan Anda (misal: makanan masih lezat, porsi mantap, dsb)...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            // Get current user display name
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(order.userId)
                                .get();
                            String userName = order.userName;
                            if (userName.isEmpty && userDoc.exists) {
                              userName = userDoc.data()?['name'] ?? '';
                            }
                            if (userName.isEmpty) {
                              userName =
                                  FirebaseAuth
                                      .instance
                                      .currentUser
                                      ?.displayName ??
                                  'Pengguna Fodos';
                            }

                            // Write reviews for each item product in the order
                            final batch = FirebaseFirestore.instance.batch();
                            final reviewsRef = FirebaseFirestore.instance
                                .collection('reviews');

                            for (final item in order.items) {
                              final prodId = item.productId.isNotEmpty
                                  ? item.productId
                                  : '';
                              if (prodId.isNotEmpty) {
                                final newDoc = reviewsRef.doc();
                                final review = ReviewModel(
                                  id: newDoc.id,
                                  orderId: order.id,
                                  productId: prodId,
                                  userId: order.userId,
                                  userName: userName,
                                  rating: selectedRating,
                                  ulasan: ulasanController.text.trim(),
                                  createdAt: DateTime.now(),
                                );
                                batch.set(newDoc, review.toFirestore());
                              }
                            }

                            // Update order status: isReviewed = true
                            final orderDoc = FirebaseFirestore.instance
                                .collection('orders')
                                .doc(order.id);
                            batch.update(orderDoc, {
                              'isReviewed': true,
                              'rating': selectedRating,
                            });

                            await batch.commit();

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Terima kasih! Ulasan Anda berhasil dikirim.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengirim ulasan: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kirim Ulasan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _streamHistoryOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Riwayat pesanan kosong',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Semua transaksi penyelamatan makanan Anda yang telah selesai atau dibatalkan akan muncul di sini.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final historyOrders = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: historyOrders.length,
          itemBuilder: (context, index) {
            final order = historyOrders[index];
            final firstItem = order.items.isNotEmpty
                ? order.items.first
                : OrderItemModel(
                    productId: '',
                    namaProduk:
                        'Pesanan #${order.id.substring(0, 5.clamp(0, order.id.length))}',
                    gambarUrl: '',
                    harga: order.totalHarga,
                  );

            final bool isSelesai = order.status.toLowerCase() == 'selesai';
            final String summary = order.items.length > 1
                ? "${firstItem.namaProduk} (+${order.items.length - 1} item lainnya)"
                : firstItem.namaProduk;

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
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order header with status and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.createdAt.toLocal().toString().substring(0, 16),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelesai
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelesai
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: AppColors.border),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: _buildItemImage(firstItem.gambarUrl),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title, Shop, Price details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (firstItem.namaToko.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  firstItem.namaToko,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                "${order.totalItem} porsi • Rp ${order.totalHarga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Review Action Row for Completed Orders
                    if (isSelesai) ...[
                      const Divider(height: 18, color: AppColors.border),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('orderId', isEqualTo: order.id)
                            .snapshots(),
                        builder: (context, reviewSnapshot) {
                          final hasReviewDoc =
                              reviewSnapshot.hasData &&
                              reviewSnapshot.data!.docs.isNotEmpty;

                          if (hasReviewDoc) {
                            final reviewData =
                                reviewSnapshot.data!.docs.first.data()
                                    as Map<String, dynamic>?;
                            final ratingVal =
                                (reviewData?['rating'] as num?)?.toDouble() ??
                                5.0;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Sudah Diulas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ratingVal.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _tampilkanDialogUlasan(context, order),
                              icon: const Icon(
                                Icons.star_rate_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Beri Ulasan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
