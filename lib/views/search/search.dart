import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/widgets/widget_display_produk.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/model/produk_model.dart';
import 'package:fodos/views/home/detail_makanan.dart';

class HalamanPencarianFodos extends StatefulWidget {
  const HalamanPencarianFodos({super.key});

  @override
  State<HalamanPencarianFodos> createState() => _HalamanPencarianFodosState();
}

class _HalamanPencarianFodosState extends State<HalamanPencarianFodos> {
  final TextEditingController _searchController = TextEditingController();
  List<ProdukModel> _allProduk = [];
  List<ProdukModel> _filteredProduk = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await DBHelper().getAllProduk();
      if (!mounted) return;
      setState(() {
        _allProduk = products;
        _filteredProduk = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProduk = _allProduk;
      } else {
        _filteredProduk = _allProduk.where((produk) {
          final namaProdukMatches =
              produk.namaProduk.toLowerCase().contains(query);
          final namaTokoMatches =
              produk.namaToko.toLowerCase().contains(query);
          final kategoriMatches =
              produk.kategori.toLowerCase().contains(query);
          return namaProdukMatches || namaTokoMatches || kategoriMatches;
        }).toList();
      }
    });
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Makanan Tidak Ditemukan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Coba gunakan kata kunci lain atau periksa kembali ejaan produk yang Anda cari.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Cari Makanan",
          style: AppTextstyle.heading1,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "Masukkan nama makanan atau toko...",
                    hintStyle: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.tune,
                            color: AppColors.primary,
                            size: 20,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _filteredProduk.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredProduk.length,
                          itemBuilder: (context, index) {
                            final produk = _filteredProduk[index];
                            return displayProduk(
                              image: produk.gambar,
                              namaMakanan: produk.namaProduk,
                              namaToko: produk.namaToko,
                              sisaPorsi: produk.stok.toString(),
                              pickUp: "19:00 - 20:30", // Mock pickup time
                              harga:
                                  "Rp ${produk.harga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailMakanan(produk: produk),
                                  ),
                                ).then((_) => _fetchProducts());
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
