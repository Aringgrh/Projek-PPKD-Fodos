import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/bottom_nav.dart';
import 'package:fodos/widgets/app_image_loader.dart';

class HalamanPembayaran extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? namaToko;
  final bool isFromCart;
  final List<String> cartItemDocIds;

  const HalamanPembayaran({
    super.key,
    required this.items,
    this.namaToko,
    this.isFromCart = false,
    this.cartItemDocIds = const [],
  });

  @override
  State<HalamanPembayaran> createState() => _HalamanPembayaranState();
}

class _HalamanPembayaranState extends State<HalamanPembayaran> {
  // Metode Pembayaran yang dipilih (Hanya metode non-tunai / digital)
  String _selectedPaymentMethod = 'QRIS Instan';

  // Controller data pemesan
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _userId = '';
  bool _isLoadingUserData = true;
  bool _isSubmitting = false;

  final double _biayaLayanan = 1000;

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String _formatRupiah(num value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _loadInitialUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? (PreferenceHandler.getUserEmail() ?? 'guest');
      _userId = uid;

      String initialName = user?.displayName ?? 'Pengguna Fodos';
      String initialPhone = user?.phoneNumber ?? '';

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final userModel = UserModelFirebase.fromJson(doc.data()!);
          if (userModel.name.isNotEmpty) initialName = userModel.name;
          if (userModel.nomor.isNotEmpty) initialPhone = userModel.nomor;
        }
      }

      if (mounted) {
        setState(() {
          _namaController.text = initialName;
          _teleponController.text = initialPhone;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data in HalamanPembayaran: $e");
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  double get _subtotal {
    return widget.items.fold<double>(
      0.0,
      (double total, item) => total + item.subtotal,
    );
  }

  double get _totalBayar {
    return _subtotal + _biayaLayanan;
  }

  String get _resolvedStoreName {
    if (widget.namaToko != null && widget.namaToko!.isNotEmpty) {
      return widget.namaToko!;
    }
    if (widget.items.isNotEmpty && widget.items.first.namaToko.isNotEmpty) {
      return widget.items.first.namaToko;
    }
    return 'Toko Mitra Fodos';
  }

  Future<void> _prosesPembayaran() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = _userId.isNotEmpty
          ? _userId
          : (user?.uid ?? PreferenceHandler.getUserEmail() ?? 'guest');

      final order = OrderModelFirebase(
        userId: uid,
        userName: _namaController.text.trim().isNotEmpty
            ? _namaController.text.trim()
            : (user?.displayName ?? 'Pengguna Fodos'),
        userPhone: _teleponController.text.trim(),
        alamatPengiriman: 'Ambil di Toko ($_resolvedStoreName)',
        items: widget.items,
        totalHarga: _totalBayar,
        totalItem: widget.items.fold<int>(
          0,
          (int total, item) => total + item.jumlah,
        ),
        ongkir: 0.0,
        metodePembayaran: _selectedPaymentMethod,
        catatan: _catatanController.text.trim(),
        status: 'Diproses',
      );

      // 1. Simpan order ke Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toFirestore());

      // 2. Jika dipesan dari keranjang, hapus dokumen keranjang
      if (widget.isFromCart && widget.cartItemDocIds.isNotEmpty) {
        for (final cartId in widget.cartItemDocIds) {
          try {
            await FirebaseFirestore.instance
                .collection('carts')
                .doc(cartId)
                .delete();
          } catch (err) {
            debugPrint('Error deleting cart item $cartId: $err');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // 3. Tampilkan modal dialog sukses transaksi
      _showSuccessDialog(docRef.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String orderDocId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Animasi Sukses
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.secondary,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pesanan Berhasil Dibuat!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan ambil pesanan Anda langsung di $_resolvedStoreName setelah status pesanan selesai diproses.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Metode Pengambilan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const Text(
                            'Ambil di Toko (Pickup)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Metode Bayar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _selectedPaymentMethod,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          Text(
                            _formatRupiah(_totalBayar),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol "Lihat Status Pesanan"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pushAndRemoveAll(
                        const BottomNavTugas12(initialIndex: 2),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text(
                      'Lihat Status Pesanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tombol "Kembali ke Beranda"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pushAndRemoveAll(
                        const BottomNavTugas12(initialIndex: 0),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pembayaran & Checkout',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingUserData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Info Pengambilan Toko & Data Pemesan
                    _buildPickupAndCustomerCard(),
                    const SizedBox(height: 16),

                    // Section 2: Ringkasan Produk yang dipesan
                    _buildOrderItemsSummary(),
                    const SizedBox(height: 16),

                    // Section 3: Pilihan Metode Pembayaran (Digital Only)
                    _buildPaymentMethodSelector(),
                    const SizedBox(height: 16),

                    // Section 4: Rincian Tagihan & Biaya
                    _buildBillingSummary(),
                    const SizedBox(
                      height: 100,
                    ), // padding untuk sticky bottom bar
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildStickyBottomBar(),
    );
  }

  Widget _buildPickupAndCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toko Pengambilan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metode Pengambilan',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                    Text(
                      'Ambil Sendiri di Toko (Pickup)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Box Detail Toko Mitra
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resolvedStoreName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Estimasi siap diambil: 15 - 30 menit setelah pesanan dikonfirmasi.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 28),

          // Label Data Kontak Pengambil
          const Row(
            children: [
              Text(
                'Data Pengambil Pesanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Field Nama Pemesan
          TextFormField(
            controller: _namaController,
            decoration: InputDecoration(
              labelText: 'Nama Pengambil',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Nama tidak boleh kosong'
                : null,
          ),
          const SizedBox(height: 12),

          // Field Nomor HP/WA
          TextFormField(
            controller: _teleponController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor WhatsApp / HP',
              hintText: 'Contoh: 08123456789',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Nomor telepon wajib diisi untuk verifikasi kasir'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Rincian Makanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.items.length} Menu',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gambar Produk
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: AppImageLoader(
                        imageUrl: item.gambarUrl,
                        fit: BoxFit.cover,
                        width: 58,
                        height: 58,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info Produk
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaProduk,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.namaToko.isNotEmpty
                              ? item.namaToko
                              : _resolvedStoreName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.jumlah}x ${_formatRupiah(item.harga)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              _formatRupiah(item.subtotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Catatan Tambahan
          TextFormField(
            controller: _catatanController,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan pesanan (opsional)...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
              prefixIcon: const Icon(Icons.edit_note, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final List<Map<String, dynamic>> methods = [
      {
        'id': 'QRIS Instan',
        'title': 'QRIS Instan',
        'subtitle': 'Scan QR Code langsung dari semua Bank & E-Wallet',
        'icon': Icons.qr_code_scanner_rounded,
        'badge': 'Rekomendasi',
        'badgeColor': AppColors.secondary,
      },
      {
        'id': 'GoPay',
        'title': 'GoPay / GoPay Later',
        'subtitle': 'Saldo & limit GoPay instan terintegrasi',
        'icon': Icons.account_balance_wallet_rounded,
        'badge': 'E-Wallet',
        'badgeColor': Colors.teal,
      },
      {
        'id': 'DANA / OVO / ShopeePay',
        'title': 'DANA / OVO / ShopeePay',
        'subtitle': 'Pembayaran cepat via dompet digital favorit',
        'icon': Icons.wallet_rounded,
        'badge': 'E-Wallet',
        'badgeColor': Colors.orange.shade800,
      },
      {
        'id': 'BCA Virtual Account',
        'title': 'BCA Virtual Account',
        'subtitle': 'Transfer cepat verifikasi otomatis 24 Jam',
        'icon': Icons.account_balance_rounded,
        'badge': 'Bank Transfer',
        'badgeColor': Colors.indigo,
      },
      {
        'id': 'Mandiri / BRI / BNI VA',
        'title': 'Mandiri / BRI / BNI Virtual Account',
        'subtitle': 'Bayar via m-Banking, ATM, atau Internet Banking',
        'icon': Icons.credit_card_rounded,
        'badge': 'Bank Transfer',
        'badgeColor': Colors.purple.shade700,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pilih Metode Pembayaran Non-Tunai',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: methods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final method = methods[index];
              final isSelected = _selectedPaymentMethod == method['id'];

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method['id'];
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method['icon'] as IconData,
                          size: 20,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    method['title'],
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                if (method['badge'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (method['badgeColor'] as Color)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      method['badge'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: method['badgeColor'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method['subtitle'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textGrey.withValues(alpha: 0.6),
                            width: isSelected ? 6 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Ringkasan Biaya',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal Makanan',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              Text(
                _formatRupiah(_subtotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Pengambilan Toko',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              Text(
                'GRATIS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biaya Layanan Aplikasi',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              Text(
                _formatRupiah(_biayaLayanan),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _formatRupiah(_totalBayar),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatRupiah(_totalBayar),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _prosesPembayaran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.secondary.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
