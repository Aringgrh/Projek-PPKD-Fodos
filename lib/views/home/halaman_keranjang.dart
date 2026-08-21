import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/model/pesanan_aktif_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class HalamanKeranjang extends StatefulWidget {
  const HalamanKeranjang({super.key});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  int userId = 1;
  double totalCartPrice = 0.0;
  Set<int> selectedCartIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email =  PreferenceHandler.getUserEmail();
    if (email != null) {
      final user = await DBHelper().getUserByEmail(email);
      if (user != null && user.id != null) {
        setState(() {
          userId = user.id!;
        });
      }
    }
  }

  void _calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      final cartId = item['cart_id'] as int;
      if (selectedCartIds.contains(cartId)) {
        final double harga = item['harga'] is int 
            ? (item['harga'] as int).toDouble() 
            : (item['harga'] ?? 0.0) as double;
        final int jumlah = (item['jumlah'] ?? 0) as int;
        total += harga * jumlah;
      }
    }
    // Update state after build completes to avoid setState during build errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && totalCartPrice != total) {
        setState(() {
          totalCartPrice = total;
        });
      }
    });
  }

  Future<void> _checkout(List<Map<String, dynamic>> cartItems) async {
    final selectedItems = cartItems.where((item) => selectedCartIds.contains(item['cart_id'])).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu produk untuk dipesan')),
      );
      return;
    }

    // Periksa stok produk untuk semua item yang dipilih
    for (var item in selectedItems) {
      final produkId = item['produk_id'] as int;
      final jumlah = item['jumlah'] as int;
      final namaProduk = (item['nama_produk'] ?? 'Produk') as String;
      final latestProduk = await DBHelper().getProdukById(produkId);
      final currentStok = latestProduk?.stok ?? 0;

      if (currentStok < jumlah) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentStok <= 0
                    ? 'Stok "$namaProduk" telah habis!'
                    : 'Stok "$namaProduk" tidak mencukupi (sisa: $currentStok porsi).',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    for (var item in selectedItems) {
      final produkId = item['produk_id'] as int;
      final jumlah = item['jumlah'] as int;
      final double harga = item['harga'] is int 
          ? (item['harga'] as int).toDouble() 
          : (item['harga'] ?? 0.0) as double;
      final gambar = (item['gambar'] ?? '') as String;

      final pesanan = PesananAktifModel(
        userId: userId,
        produkId: produkId,
        jumlah: jumlah,
        totalHarga: harga * jumlah,
        tanggal: DateTime.now().toLocal().toString().substring(0, 16),
        status: 'Sedang Diproses',
        gambar: gambar,
      );

      await DBHelper().insertPesananAktif(pesanan);
      // Remove checked out item from database cart
      await DBHelper().deleteKeranjang(item['cart_id'] as int);
    }

    // Reset selection state
    setState(() {
      _isInitialized = false;
      selectedCartIds.clear();
      totalCartPrice = 0.0;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pesanan Berhasil'),
          content: const Text(
            'Pesanan Anda telah berhasil dibuat! Silakan cek di tab "Pesanan".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Back to Home with result
              },
              child: const Text('OK'),
            ),
          ],
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
          'Keranjang Penyelamatan',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper().getCartWithProductDetails(userId),
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
            selectedCartIds = cartItems.map((item) => item['cart_id'] as int).toSet();
            _isInitialized = true;
          }

          _calculateTotal(cartItems);

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final int cartId = item['cart_id'] as int;
                  final String namaMakanan = (item['nama_produk'] ?? '') as String;
                  final String namaToko = (item['nama_toko'] ?? '') as String;
                  final double harga = item['harga'] is int 
                      ? (item['harga'] as int).toDouble() 
                      : (item['harga'] ?? 0.0) as double;
                  final int jumlah = (item['jumlah'] ?? 0) as int;
                  final String gambar = (item['gambar'] ?? '') as String;
                  final bool isSelected = selectedCartIds.contains(cartId);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                                selectedCartIds.add(cartId);
                              } else {
                                selectedCartIds.remove(cartId);
                              }
                            });
                          },
                        ),

                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 75,
                            height: 75,
                            color: Colors.grey[200],
                            child: gambar.startsWith('assets/')
                                ? Image.asset(gambar, fit: BoxFit.cover)
                                : Image.network(gambar, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title, Shop & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaMakanan,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                namaToko,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Rp ${harga.toInt().toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]}.',
                                    )}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controls (Qty & Delete)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await DBHelper().deleteKeranjang(cartId);
                                  setState(() {
                                    selectedCartIds.remove(cartId);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        if (jumlah > 1) {
                                          await DBHelper().updateKeranjangJumlah(cartId, jumlah - 1);
                                          setState(() {});
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                                        child: Icon(Icons.remove, size: 12, color: AppColors.primary),
                                      ),
                                    ),
                                    Text(
                                      '$jumlah',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await DBHelper().updateKeranjangJumlah(cartId, jumlah + 1);
                                        setState(() {});
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                                        child: Icon(Icons.add, size: 12, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Bottom Total Sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Total Penyelamatan (${selectedCartIds.length} item)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Rp ${totalCartPrice.toInt().toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]}.',
                                    )}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedCartIds.isEmpty ? null : () => _checkout(cartItems),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Konfirmasi Penyelamatan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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
