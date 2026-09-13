import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/product_model.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/service/seller_service.dart';
import 'package:fodos/widgets/bottom_nav.dart';
import 'package:fodos/widgets/widget_seller_metric_card.dart';
import 'package:fodos/widgets/widget_seller_info_tile.dart';
import 'package:fodos/widgets/widget_seller_product_card.dart';
import 'package:fodos/widgets/widget_seller_order_card.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StoreModel? _store;
  bool _isLoading = true;

  List<ProductModel> _sellerProducts = [];
  List<SellerOrderModel> _incomingOrders = [];
  StreamSubscription<List<SellerOrderModel>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadDashboardData();
  }

  void _handleTabSelection() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final store = await SellerService.getStore();
    final products = await SellerService.getSellerProducts();
    final orders = await SellerService.getSellerOrders();

    if (mounted) {
      setState(() {
        _store = store;
        _sellerProducts = products;
        _incomingOrders = orders;
        _isLoading = false;
      });

      if (store != null && store.namaToko.isNotEmpty) {
        _ordersSubscription?.cancel();
        _ordersSubscription = SellerService.streamSellerOrders(store.namaToko)
            .listen((newOrders) {
              if (mounted) {
                setState(() {
                  _incomingOrders = newOrders;
                });
              }
            });
      }
    }
  }

  int get _newOrdersCount =>
      _incomingOrders.where((o) => o.status == 'Pesanan Baru').length;
  int get _inProcessCount =>
      _incomingOrders.where((o) => o.status == 'Diproses').length;
  int get _completedCount =>
      _incomingOrders.where((o) => o.status == 'Selesai').length;
  double get _todaySalesTotal {
    return _incomingOrders
        .where((o) => o.status == 'Diproses' || o.status == 'Selesai')
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _showAddProductBottomSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    String category = _store?.kategori ?? 'Makanan Berat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (modalContext, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tambah Produk Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => modalContext.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga (Rp)',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items:
                        [
                              'Makanan Berat',
                              'Minuman',
                              'Cemilan & Snack',
                              'Roti',
                              'Fast Food',
                              'Kopi & Dessert',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar Produk',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            priceCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nama dan harga wajib diisi!'),
                            ),
                          );
                          return;
                        }

                        final newProduct = ProductModel(
                          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                          namaProduk: nameCtrl.text.trim(),
                          namaToko: _store?.namaToko ?? 'Toko Saya',
                          alamatToko: _store?.alamatToko ?? '',
                          kategori: category,
                          gambarUrl: imageCtrl.text.trim().isNotEmpty
                              ? imageCtrl.text.trim()
                              : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400',
                          harga: double.tryParse(priceCtrl.text) ?? 0.0,
                          stok: int.tryParse(stockCtrl.text) ?? 10,
                          deskripsi: '',
                        );

                        await SellerService.addSellerProduct(newProduct);
                        if (modalContext.mounted) modalContext.pop();
                        _loadDashboardData();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Produk "${newProduct.namaProduk}" berhasil ditambahkan!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showEditProductBottomSheet(ProductModel product) {
    final nameCtrl = TextEditingController(text: product.namaProduk);
    final priceCtrl = TextEditingController(
      text: product.harga.toInt().toString(),
    );
    final stockCtrl = TextEditingController(text: product.stok.toString());
    final imageCtrl = TextEditingController(text: product.gambarUrl);
    String category = product.kategori;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (modalContext, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit Produk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => modalContext.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga (Rp)',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        [
                          'Makanan Berat',
                          'Minuman',
                          'Cemilan & Snack',
                          'Kue & Roti',
                          'Fast Food',
                          'Kopi & Dessert',
                        ].contains(category)
                        ? category
                        : 'Makanan Berat',
                    items:
                        [
                              'Makanan Berat',
                              'Minuman',
                              'Cemilan & Snack',
                              'Kue & Roti',
                              'Fast Food',
                              'Kopi & Dessert',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar Produk',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            priceCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nama dan harga wajib diisi!'),
                            ),
                          );
                          return;
                        }

                        final updatedProduct = product.copyWith(
                          namaProduk: nameCtrl.text.trim(),
                          kategori: category,
                          gambarUrl: imageCtrl.text.trim().isNotEmpty
                              ? imageCtrl.text.trim()
                              : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400',
                          harga: double.tryParse(priceCtrl.text) ?? 0.0,
                          stok: int.tryParse(stockCtrl.text) ?? 10,
                          deskripsi: '',
                        );

                        await SellerService.updateSellerProduct(updatedProduct);
                        if (modalContext.mounted) modalContext.pop();
                        _loadDashboardData();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Produk "${updatedProduct.namaProduk}" berhasil diupdate!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _store?.namaToko ?? 'Dashboard Penjual',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'POV Penjual (Seller Mode)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await PreferenceHandler.setSellerMode(false);
              if (context.mounted) {
                if (Navigator.canPop(context)) {
                  context.pop();
                } else {
                  context.pushAndRemoveAll(const BottomNavTugas12());
                }
              }
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
            label: const Text(
              'Mode Pembeli',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Metric Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    widgetSellerMetricCard(
                      title: 'Pesanan Baru',
                      value: '$_newOrdersCount',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    widgetSellerMetricCard(
                      title: 'Diproses',
                      value: '$_inProcessCount',
                      icon: Icons.soup_kitchen_outlined,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    widgetSellerMetricCard(
                      title: 'Selesai',
                      value: '$_completedCount',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    widgetSellerMetricCard(
                      title: 'Penjualan',
                      value: 'Rp ${_formatRupiah(_todaySalesTotal)}',
                      icon: Icons.payments_outlined,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar Navigation
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Kelola Menu'),
                Tab(text: 'Pesanan Masuk'),
                Tab(text: 'Pengaturan'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKelolaMenuTab(),
                _buildPesananMasukTab(),
                _buildPengaturanTokoTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddProductBottomSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // --- TAB 1: KELOLA MENU ---
  Widget _buildKelolaMenuTab() {
    if (_sellerProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada menu produk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tambahkan produk pertamamu untuk mulai berjualan',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddProductBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Produk',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sellerProducts.length,
      itemBuilder: (context, index) {
        final product = _sellerProducts[index];
        return widgetSellerProductCard(
          product: product,
          onEdit: () => _showEditProductBottomSheet(product),
          onDelete: () async {
            await SellerService.deleteSellerProduct(product.id);
            _loadDashboardData();
          },
        );
      },
    );
  }

  // --- TAB 2: PESANAN MASUK ---
  Widget _buildPesananMasukTab() {
    if (_incomingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada pesanan masuk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pesanan dari pembeli akan muncul di sini',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incomingOrders.length,
      itemBuilder: (context, index) {
        final order = _incomingOrders[index];
        return widgetSellerOrderCard(
          context: context,
          order: order,
          onReject: () async {
            try {
              // Kembalikan stok / porsi produk di database saat pesanan ditolak
              final orderDoc = await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .get();
              if (orderDoc.exists && orderDoc.data() != null) {
                final data = orderDoc.data()!;
                final items = data['items'] as List<dynamic>? ?? [];
                for (final itemData in items) {
                  if (itemData is Map<String, dynamic>) {
                    final productId = itemData['productId'] as String? ?? '';
                    final jumlah = (itemData['jumlah'] as num?)?.toInt() ?? 0;
                    if (productId.isNotEmpty && jumlah > 0) {
                      try {
                        final prodDoc = FirebaseFirestore.instance
                            .collection('products')
                            .doc(productId);
                        await FirebaseFirestore.instance.runTransaction((
                          transaction,
                        ) async {
                          final snapshot = await transaction.get(prodDoc);
                          if (snapshot.exists) {
                            final currentStok =
                                (snapshot.data()?['stok'] as num?)?.toInt() ??
                                0;
                            final newStok = (currentStok + jumlah)
                                .clamp(0, 999999)
                                .toInt();
                            transaction.update(prodDoc, {'stok': newStok});
                          }
                        });
                      } catch (e) {
                        debugPrint('Gagal mengembalikan stok $productId: $e');
                      }
                    }
                  }
                }
              }

              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .update({
                    'status': 'Ditolak',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              setState(() {
                _incomingOrders[index] = SellerOrderModel(
                  orderId: order.orderId,
                  customerName: order.customerName,
                  itemsSummary: order.itemsSummary,
                  totalPrice: order.totalPrice,
                  status: 'Ditolak',
                  createdAt: order.createdAt,
                );
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menolak pesanan: $e')),
              );
            }
          },
          onAccept: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .update({
                    'status': 'Diterima',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              setState(() {
                _incomingOrders[index] = SellerOrderModel(
                  orderId: order.orderId,
                  customerName: order.customerName,
                  itemsSummary: order.itemsSummary,
                  totalPrice: order.totalPrice,
                  status: 'Diterima',
                  createdAt: order.createdAt,
                );
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesanan ${order.orderId} telah diterima!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
          onProcess: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .update({
                    'status': 'Diproses',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              setState(() {
                _incomingOrders[index] = SellerOrderModel(
                  orderId: order.orderId,
                  customerName: order.customerName,
                  itemsSummary: order.itemsSummary,
                  totalPrice: order.totalPrice,
                  status: 'Diproses',
                  createdAt: order.createdAt,
                );
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesanan ${order.orderId} mulai diproses!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
          onCancel: () async {
            try {
              final orderDoc = await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .get();
              if (orderDoc.exists && orderDoc.data() != null) {
                final data = orderDoc.data()!;
                final items = data['items'] as List<dynamic>? ?? [];
                for (final itemData in items) {
                  if (itemData is Map<String, dynamic>) {
                    final productId = itemData['productId'] as String? ?? '';
                    final jumlah = (itemData['jumlah'] as num?)?.toInt() ?? 0;
                    if (productId.isNotEmpty && jumlah > 0) {
                      try {
                        final prodDoc = FirebaseFirestore.instance
                            .collection('products')
                            .doc(productId);
                        await FirebaseFirestore.instance.runTransaction((
                          transaction,
                        ) async {
                          final snapshot = await transaction.get(prodDoc);
                          if (snapshot.exists) {
                            final currentStok =
                                (snapshot.data()?['stok'] as num?)?.toInt() ??
                                0;
                            final newStok = (currentStok + jumlah)
                                .clamp(0, 999999)
                                .toInt();
                            transaction.update(prodDoc, {'stok': newStok});
                          }
                        });
                      } catch (e) {
                        debugPrint('Gagal mengembalikan stok $productId: $e');
                      }
                    }
                  }
                }
              }

              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .update({
                    'status': 'Dibatalkan',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              setState(() {
                _incomingOrders[index] = SellerOrderModel(
                  orderId: order.orderId,
                  customerName: order.customerName,
                  itemsSummary: order.itemsSummary,
                  totalPrice: order.totalPrice,
                  status: 'Dibatalkan',
                  createdAt: order.createdAt,
                );
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesanan ${order.orderId} telah dibatalkan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
          onComplete: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.orderId)
                  .update({
                    'status': 'Selesai',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              setState(() {
                _incomingOrders[index] = SellerOrderModel(
                  orderId: order.orderId,
                  customerName: order.customerName,
                  itemsSummary: order.itemsSummary,
                  totalPrice: order.totalPrice,
                  status: 'Selesai',
                  createdAt: order.createdAt,
                );
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pesanan ${order.orderId} telah diselesaikan!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
        );
      },
    );
  }

  // --- TAB 3: PENGATURAN TOKO ---
  Widget _buildPengaturanTokoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                widgetSellerInfoTile(
                  icon: Icons.storefront,
                  title: 'Nama Toko',
                  subtitle: _store?.namaToko ?? '-',
                ),
                const Divider(),
                widgetSellerInfoTile(
                  icon: Icons.category_outlined,
                  title: 'Kategori Utama',
                  subtitle: _store?.kategori ?? '-',
                ),
                const Divider(),
                widgetSellerInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat Toko',
                  subtitle: _store?.alamatToko ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Informasi toko telah diperbarui'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: const Text(
              'Edit Profil Toko',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
