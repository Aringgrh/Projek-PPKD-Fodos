import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/address_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class HalamanPilihLokasi extends StatefulWidget {
  const HalamanPilihLokasi({super.key});

  @override
  State<HalamanPilihLokasi> createState() => _HalamanPilihLokasiState();
}

class _HalamanPilihLokasiState extends State<HalamanPilihLokasi> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLocation = '';
  List<AddressModel> _savedAddresses = [];
  int _selectedRegionIndex = 0;
  bool _isDetectingLocation = false;

  final List<String> _regions = [
    'Semua',
    'Jakarta Pusat',
    'Jakarta Selatan',
    'Jakarta Barat',
    'Jakarta Utara',
    'Jakarta Timur',
    'Bandung',
    'Surabaya',
  ];

  final List<Map<String, dynamic>> _popularAreas = [
    {
      'title': 'Sudirman & SCBD',
      'region': 'Jakarta Selatan',
      'address': 'Kawasan Sudirman Central Business District (SCBD)',
      'stores': '18 Toko Mitra',
      'icon': Icons.apartment_rounded,
    },
    {
      'title': 'Thamrin & Menteng',
      'region': 'Jakarta Pusat',
      'address': 'Jl. M.H. Thamrin & Sekitarnya, Menteng',
      'stores': '14 Toko Mitra',
      'icon': Icons.location_city_rounded,
    },
    {
      'title': 'Senopati & Gunawarman',
      'region': 'Jakarta Selatan',
      'address': 'Kawasan Kuliner Senopati, Kebayoran Baru',
      'stores': '22 Toko Mitra',
      'icon': Icons.restaurant_rounded,
    },
    {
      'title': 'Kemang Raya',
      'region': 'Jakarta Selatan',
      'address': 'Jl. Kemang Raya & Bangka, Mampang Prapatan',
      'stores': '16 Toko Mitra',
      'icon': Icons.coffee_rounded,
    },
    {
      'title': 'Pantai Indah Kapuk (PIK)',
      'region': 'Jakarta Utara',
      'address': 'Kawasan Kuliner PIK 1 & PIK 2, Penjaringan',
      'stores': '25 Toko Mitra',
      'icon': Icons.storefront_rounded,
    },
    {
      'title': 'Kelapa Gading Boulevard',
      'region': 'Jakarta Utara',
      'address': 'Jl. Boulevard Raya, Kelapa Gading',
      'stores': '19 Toko Mitra',
      'icon': Icons.bakery_dining_rounded,
    },
    {
      'title': 'Tanjung Duren & Grogol',
      'region': 'Jakarta Barat',
      'address': 'Jl. Tanjung Duren Raya & Green Ville',
      'stores': '15 Toko Mitra',
      'icon': Icons.fastfood_rounded,
    },
    {
      'title': 'Rawamangun & Matraman',
      'region': 'Jakarta Timur',
      'address': 'Jl. Pemuda & Balai Pustaka, Rawamangun',
      'stores': '11 Toko Mitra',
      'icon': Icons.local_dining_rounded,
    },
    {
      'title': 'Dago & Dipatiukur',
      'region': 'Bandung',
      'address': 'Jl. Ir. H. Juanda (Dago) & Dipatiukur, Bandung',
      'stores': '17 Toko Mitra',
      'icon': Icons.coffee_outlined,
    },
    {
      'title': 'Tunjungan & Gubeng',
      'region': 'Surabaya',
      'address': 'Jl. Tunjungan & Jl. Raya Gubeng, Surabaya',
      'stores': '13 Toko Mitra',
      'icon': Icons.location_on_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    setState(() {
      _selectedLocation = PreferenceHandler.getSelectedLocation();
      _savedAddresses = PreferenceHandler.getSavedAddresses();
    });
  }

  Future<void> _selectLocation(String title, {String detail = "Sekitar kamu"}) async {
    await PreferenceHandler.setSelectedLocation(title, detail: detail);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lokasi diatur ke: $title',
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, {
      'title': title,
      'detail': detail,
    });
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    // Simulasi deteksi GPS akurasi tinggi
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _isDetectingLocation = false;
    });

    const gpsTitle = "Jl. M.H. Thamrin No. 28";
    const gpsDetail = "Menteng, Jakarta Pusat (Lokasi Saat Ini)";
    await _selectLocation(gpsTitle, detail: gpsDetail);
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'rumah':
        return Icons.home_rounded;
      case 'kantor':
        return Icons.business_rounded;
      case 'apartemen':
        return Icons.apartment_rounded;
      case 'kos':
        return Icons.hotel_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  void _showAddAddressBottomSheet({AddressModel? editItem}) {
    final titleController = TextEditingController(text: editItem?.address ?? '');
    final detailController = TextEditingController(text: editItem?.detail ?? '');
    final nameController = TextEditingController(text: editItem?.receiverName ?? '');
    final phoneController = TextEditingController(text: editItem?.receiverPhone ?? '');
    String selectedLabel = editItem?.label ?? 'Rumah';
    final formKey = GlobalKey<FormState>();

    final List<String> availableLabels = [
      'Rumah',
      'Kantor',
      'Apartemen',
      'Kos',
      'Lainnya',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Drag handle
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
                          Text(
                            editItem == null ? "Tambah Alamat Baru" : "Ubah Alamat",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, color: AppColors.textGrey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Label selection chips
                      const Text(
                        "Label Alamat",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: availableLabels.map((label) {
                          final isSelected = selectedLabel == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedLabel = label;
                                });
                              }
                            },
                            selectedColor: AppColors.secondary,
                            backgroundColor: AppColors.background,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            avatar: Icon(
                              _getIconForLabel(label),
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.textGrey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.secondary : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Alamat Lengkap
                      const Text(
                        "Alamat / Jalan / Gedung",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: "Contoh: Jl. Senopati No. 12, Kebayoran Baru",
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Alamat tidak boleh kosong";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Detail / Patokan
                      const Text(
                        "Detail / Catatan Patokan (Opsional)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: detailController,
                        decoration: InputDecoration(
                          hintText: "Contoh: Blok C No. 5, Pagar Hitam, Samping Alfamart",
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textGrey, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final newAddr = AddressModel(
                              id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              label: selectedLabel,
                              address: titleController.text.trim(),
                              detail: detailController.text.trim(),
                              receiverName: nameController.text.trim(),
                              receiverPhone: phoneController.text.trim(),
                              isDefault: editItem?.isDefault ?? false,
                            );

                            if (editItem == null) {
                              await PreferenceHandler.addSavedAddress(newAddr);
                            } else {
                              await PreferenceHandler.updateSavedAddress(newAddr);
                            }

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _loadInitialData();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  editItem == null
                                      ? "Alamat baru berhasil ditambahkan!"
                                      : "Alamat berhasil diperbarui!",
                                ),
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            editItem == null ? "Simpan Alamat" : "Perbarui Alamat",
                            style: const TextStyle(
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
            );
          },
        );
      },
    );
  }

  void _deleteAddress(String id) async {
    await PreferenceHandler.deleteSavedAddress(id);
    _loadInitialData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Alamat berhasil dihapus"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<AddressModel> get _filteredSavedAddresses {
    if (_searchQuery.isEmpty) return _savedAddresses;
    return _savedAddresses.where((addr) {
      return addr.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          addr.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          addr.detail.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPopularAreas {
    var list = _popularAreas;
    if (_selectedRegionIndex > 0) {
      final region = _regions[_selectedRegionIndex];
      list = list.where((item) => item['region'] == region).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final title = item['title'].toString().toLowerCase();
        final addr = item['address'].toString().toLowerCase();
        final reg = item['region'].toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return title.contains(q) || addr.contains(q) || reg.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pilih Lokasi",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Section
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari jalan, gedung, atau area...",
                      hintStyle: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textGrey,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textGrey,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Use Current Location GPS Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    onTap: _isDetectingLocation ? null : _detectCurrentLocation,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            AppColors.secondary.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: _isDetectingLocation
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.secondary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.secondary,
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        "Gunakan Lokasi Saat Ini",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "GPS",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isDetectingLocation
                                      ? "Mendeteksi sinyal GPS..."
                                      : "Jl. M.H. Thamrin No. 28, Menteng, Jakarta Pusat",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Saved Addresses Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Alamat Tersimpan",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddAddressBottomSheet(),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      label: const Text(
                        "Tambah Alamat",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Saved Addresses List
              if (_filteredSavedAddresses.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 40,
                          color: AppColors.textGrey.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tidak ada alamat tersimpan yang cocok.",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredSavedAddresses.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: AppColors.border,
                      ),
                    itemBuilder: (context, index) {
                      final addr = _filteredSavedAddresses[index];
                      final isSelected = _selectedLocation == addr.address;

                      return ListTile(
                        onTap: () => _selectLocation(addr.address, detail: addr.detail.isNotEmpty ? addr.detail : addr.label),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary.withValues(alpha: 0.12)
                                : AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForLabel(addr.label),
                            color: isSelected ? AppColors.secondary : const Color(0xFF404941),
                            size: 19,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                addr.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Aktif",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              addr.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (addr.detail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                addr.detail,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddAddressBottomSheet(editItem: addr);
                            } else if (value == 'delete') {
                              _deleteAddress(addr.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.textDark),
                                  SizedBox(width: 8),
                                  Text("Ubah", style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Hapus", style: TextStyle(fontSize: 13, color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Popular Areas Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Jelajahi Area Kuliner Populer",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Region Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _regions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedRegionIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRegionIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Text(
                          _regions[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Popular Areas Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredPopularAreas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final area = _filteredPopularAreas[index];
                  final isSelected = _selectedLocation == area['title'];

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => _selectLocation(
                        area['title'] as String,
                        detail: area['address'] as String,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.border.withValues(alpha: 0.6),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondary.withValues(alpha: 0.12)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                area['icon'] as IconData,
                                color: isSelected ? AppColors.secondary : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          area['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.badgeBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          area['stores'] as String,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.badgeText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    area['address'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.chevron_right_rounded,
                              color: isSelected ? AppColors.secondary : AppColors.textGrey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
