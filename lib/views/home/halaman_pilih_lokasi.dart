import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/address_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class HalamanPilihLokasi extends StatefulWidget {
  final bool openDirectlyToMap;

  const HalamanPilihLokasi({
    super.key,
    this.openDirectlyToMap = false,
  });

  @override
  State<HalamanPilihLokasi> createState() => _HalamanPilihLokasiState();
}

class _HalamanPilihLokasiState extends State<HalamanPilihLokasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _listSearchController = TextEditingController();
  final TextEditingController _mapSearchController = TextEditingController();
  final Geocoding _geocoding = Geocoding();

  String _searchQuery = '';
  String _selectedLocation = '';
  List<AddressModel> _savedAddresses = [];
  int _selectedRegionIndex = 0;
  bool _isDetectingLocation = false;

  // Google Maps State
  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(-6.2088, 106.8456); // Jakarta Pusat
  LatLng _currentMapPosition = _initialPosition;
  String _mapAddressTitle = "Memuat lokasi...";
  String _mapAddressDetail = "Jakarta, Indonesia";
  bool _isMapGeocoding = false;
  Timer? _debounceTimer;

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
      'latLng': const LatLng(-6.2250, 106.8097),
    },
    {
      'title': 'Thamrin & Menteng',
      'region': 'Jakarta Pusat',
      'address': 'Jl. M.H. Thamrin & Sekitarnya, Menteng',
      'stores': '14 Toko Mitra',
      'icon': Icons.location_city_rounded,
      'latLng': const LatLng(-6.1931, 106.8236),
    },
    {
      'title': 'Senopati & Gunawarman',
      'region': 'Jakarta Selatan',
      'address': 'Kawasan Kuliner Senopati, Kebayoran Baru',
      'stores': '22 Toko Mitra',
      'icon': Icons.restaurant_rounded,
      'latLng': const LatLng(-6.2366, 106.8091),
    },
    {
      'title': 'Kemang Raya',
      'region': 'Jakarta Selatan',
      'address': 'Jl. Kemang Raya & Bangka, Mampang Prapatan',
      'stores': '16 Toko Mitra',
      'icon': Icons.coffee_rounded,
      'latLng': const LatLng(-6.2738, 106.8155),
    },
    {
      'title': 'Pantai Indah Kapuk (PIK)',
      'region': 'Jakarta Utara',
      'address': 'Kawasan Kuliner PIK 1 & PIK 2, Penjaringan',
      'stores': '25 Toko Mitra',
      'icon': Icons.storefront_rounded,
      'latLng': const LatLng(-6.1118, 106.7408),
    },
    {
      'title': 'Kelapa Gading Boulevard',
      'region': 'Jakarta Utara',
      'address': 'Jl. Boulevard Raya, Kelapa Gading',
      'stores': '19 Toko Mitra',
      'icon': Icons.bakery_dining_rounded,
      'latLng': const LatLng(-6.1601, 106.9080),
    },
    {
      'title': 'Tanjung Duren & Grogol',
      'region': 'Jakarta Barat',
      'address': 'Jl. Tanjung Duren Raya & Green Ville',
      'stores': '15 Toko Mitra',
      'icon': Icons.fastfood_rounded,
      'latLng': const LatLng(-6.1724, 106.7865),
    },
    {
      'title': 'Rawamangun & Matraman',
      'region': 'Jakarta Timur',
      'address': 'Jl. Pemuda & Balai Pustaka, Rawamangun',
      'stores': '11 Toko Mitra',
      'icon': Icons.local_dining_rounded,
      'latLng': const LatLng(-6.1950, 106.8837),
    },
    {
      'title': 'Dago & Dipatiukur',
      'region': 'Bandung',
      'address': 'Jl. Ir. H. Juanda (Dago) & Dipatiukur, Bandung',
      'stores': '17 Toko Mitra',
      'icon': Icons.coffee_outlined,
      'latLng': const LatLng(-6.8890, 107.6160),
    },
    {
      'title': 'Tunjungan & Gubeng',
      'region': 'Surabaya',
      'address': 'Jl. Tunjungan & Jl. Raya Gubeng, Surabaya',
      'stores': '13 Toko Mitra',
      'icon': Icons.location_on_rounded,
      'latLng': const LatLng(-7.2600, 112.7483),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.openDirectlyToMap ? 0 : 0,
    );
    _loadInitialData();
    _reverseGeocodePosition(_initialPosition);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listSearchController.dispose();
    _mapSearchController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    setState(() {
      _selectedLocation = PreferenceHandler.getSelectedLocation();
      _savedAddresses = PreferenceHandler.getSavedAddresses();
    });
  }

  // --- Real Reverse Geocoding with Graceful Fallback ---
  Future<void> _reverseGeocodePosition(LatLng target) async {
    if (!mounted) return;
    setState(() {
      _isMapGeocoding = true;
    });

    try {
      final placemarks = await _geocoding
          .placemarkFromCoordinates(
            target.latitude,
            target.longitude,
          )
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String title = '';
        if (place.street != null && place.street!.trim().isNotEmpty) {
          title = place.street!.trim();
        } else if (place.name != null && place.name!.trim().isNotEmpty) {
          title = place.name!.trim();
        } else {
          title = "Titik Terpilih";
        }

        List<String> detailParts = [];
        if (place.subLocality != null &&
            place.subLocality!.isNotEmpty &&
            place.subLocality != title) {
          detailParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          detailParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          detailParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          detailParts.add(place.administrativeArea!);
        }

        String detail = detailParts.isEmpty
            ? "Koordinat: ${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}"
            : detailParts.join(", ");

        setState(() {
          _mapAddressTitle = title;
          _mapAddressDetail = detail;
          _isMapGeocoding = false;
        });
      } else {
        setState(() {
          _mapAddressTitle = "Titik Terpilih";
          _mapAddressDetail =
              "Koordinat: ${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}";
          _isMapGeocoding = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mapAddressTitle = "Titik Terpilih";
        _mapAddressDetail =
            "Koordinat: ${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)}";
        _isMapGeocoding = false;
      });
    }
  }

  // --- Real GPS Position Detection with Multi-stage Fallback ---
  Future<void> _detectCurrentLocation({bool moveToMap = false}) async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Layanan GPS tidak aktif. Silakan aktifkan GPS perangkat Anda."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "Pengaturan",
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Izin lokasi ditolak."),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          setState(() => _isDetectingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Izin lokasi ditolak permanen. Buka Pengaturan untuk mengizinkan."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "Buka",
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      // 1. Try fast last-known position
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Try current position with medium accuracy
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        // Fallback to low accuracy if timeout
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      }

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (moveToMap && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLatLng, zoom: 16.5),
          ),
        );
        _reverseGeocodePosition(currentLatLng);
      } else {
        // Reverse geocode and select
        String title = "Lokasi Saya";
        String detail =
            "Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";

        try {
          final placemarks = await _geocoding
              .placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              )
              .timeout(const Duration(seconds: 3));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            title = place.street?.isNotEmpty == true
                ? place.street!
                : (place.name ?? "Lokasi Saya");
            detail = [
              if (place.subLocality?.isNotEmpty == true) place.subLocality!,
              if (place.locality?.isNotEmpty == true) place.locality!,
              if (place.administrativeArea?.isNotEmpty == true) place.administrativeArea!,
            ].join(", ");
          }
        } catch (_) {}

        if (mounted) {
          setState(() => _isDetectingLocation = false);
          await _selectLocation(title, detail: detail);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mendeteksi lokasi GPS: ${e.toString()}"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  // --- Search Place by Name on Map ---
  Future<void> _searchAndAnimateToLocation(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isMapGeocoding = true;
    });

    try {
      final locations = await _geocoding
          .locationFromAddress(query)
          .timeout(const Duration(seconds: 5));

      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: target, zoom: 16.0),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lokasi '$query' tidak ditemukan"),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tidak dapat menemukan lokasi '$query'"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMapGeocoding = false;
        });
      }
    }
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

  void _showAddAddressBottomSheet({
    AddressModel? editItem,
    String? initialAddress,
    String? initialDetail,
  }) {
    final titleController = TextEditingController(
      text: editItem?.address ?? initialAddress ?? '',
    );
    final detailController = TextEditingController(
      text: editItem?.detail ?? initialDetail ?? '',
    );
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Alamat / Jalan / Gedung",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (_mapAddressTitle.isNotEmpty && _mapAddressTitle != "Memuat lokasi...")
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  titleController.text = _mapAddressTitle;
                                  detailController.text = _mapAddressDetail;
                                });
                              },
                              child: const Text(
                                "Ambil dari Pin Peta",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
                      const SizedBox(height: 14),

                      // Penerima info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Nama Penerima",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    hintText: "Nama Anda",
                                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "No. Telepon",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: "08xxxxxxxxxx",
                                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
          "Pilih Lokasi Pengantaran",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textGrey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 17),
                      SizedBox(width: 6),
                      Text("Peta Interaktif"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, size: 17),
                      SizedBox(width: 6),
                      Text("Daftar Alamat"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildInteractiveMapView(),
          _buildAddressListView(),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 1: GOOGLE MAPS INTERACTIVE PICKER
  // =========================================================================
  Widget _buildInteractiveMapView() {
    return Stack(
      children: [
        // 1. Full Interactive GoogleMap
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialPosition,
            zoom: 15.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onTap: (latLng) {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: latLng, zoom: 16.0),
              ),
            );
          },
          onCameraMove: (position) {
            _currentMapPosition = position.target;
            if (!_isMapGeocoding) {
              setState(() {
                _isMapGeocoding = true;
              });
            }
          },
          onCameraIdle: () {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 600), () {
              _reverseGeocodePosition(_currentMapPosition);
            });
          },
        ),

        // 2. Center Fixed Pin (Grab / Gojek Style Pinpoint)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 38), // Center pin tip on the exact point
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating tooltip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isMapGeocoding) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Mencari alamat...",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ] else ...[
                        const Icon(Icons.touch_app, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text(
                          "Geser peta ke titik pas",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Pin Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                // Ground shadow dot
                Container(
                  width: 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Top Floating Search Bar & Quick Location Chips
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Place on Map
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _mapSearchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) => _searchAndAnimateToLocation(query),
                  decoration: InputDecoration(
                    hintText: "Cari tempat di peta (cth: SCBD, Monas)...",
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.secondary, size: 22),
                    suffixIcon: _mapSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textGrey, size: 18),
                            onPressed: () {
                              _mapSearchController.clear();
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.secondary, size: 20),
                            onPressed: () => _searchAndAnimateToLocation(_mapSearchController.text),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Quick Location Chips on Map
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMapQuickChip("SCBD", const LatLng(-6.2250, 106.8097)),
                    _buildMapQuickChip("Menteng", const LatLng(-6.1931, 106.8236)),
                    _buildMapQuickChip("PIK", const LatLng(-6.1118, 106.7408)),
                    _buildMapQuickChip("Kemang", const LatLng(-6.2738, 106.8155)),
                    _buildMapQuickChip("Kelapa Gading", const LatLng(-6.1601, 106.9080)),
                    _buildMapQuickChip("Dago Bandung", const LatLng(-6.8890, 107.6160)),
                    _buildMapQuickChip("Surabaya", const LatLng(-7.2600, 112.7483)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. Floating Action Controls (GPS & Zoom)
        Positioned(
          right: 16,
          bottom: 220,
          child: Column(
            children: [
              // Current GPS Location Button
              FloatingActionButton.small(
                heroTag: 'gps_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
                elevation: 3,
                onPressed: _isDetectingLocation ? null : () => _detectCurrentLocation(moveToMap: true),
                child: _isDetectingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
              const SizedBox(height: 8),
              // Zoom In
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
                elevation: 3,
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                },
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 6),
              // Zoom Out
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
                elevation: 3,
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                },
                child: const Icon(Icons.remove, size: 20),
              ),
            ],
          ),
        ),

        // 5. Bottom Selected Location Confirmation Card
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: AppColors.secondary,
                        size: 24,
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
                                  _mapAddressTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isMapGeocoding)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.secondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _mapAddressDetail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // Save to Address Book
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _showAddAddressBottomSheet(
                            initialAddress: _mapAddressTitle,
                            initialDetail: _mapAddressDetail,
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18, color: AppColors.secondary),
                        label: const Text(
                          "Simpan",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Choose This Location
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          _selectLocation(
                            _mapAddressTitle,
                            detail: _mapAddressDetail,
                          );
                        },
                        child: const Text(
                          "Pilih Lokasi Ini",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildMapQuickChip(String label, LatLng latLng) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 16.0),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 13, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 2: SAVED ADDRESSES & POPULAR AREAS LIST
  // =========================================================================
  Widget _buildAddressListView() {
    return SafeArea(
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
                  controller: _listSearchController,
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
                              _listSearchController.clear();
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

            // Open Interactive Map Card Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0,
                child: InkWell(
                  onTap: () {
                    _tabController.animateTo(0);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pilih Langsung Lewat Peta",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Tentukan titik akurat pengantaran dengan pin peta",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
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
                  onTap: _isDetectingLocation ? null : () => _detectCurrentLocation(moveToMap: false),
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
                                    ? "Mendeteksi sinyal GPS akurat..."
                                    : "Deteksi titik GPS perangkat Anda secara otomatis",
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
                final LatLng? areaLatLng = area['latLng'] as LatLng?;

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
                          if (areaLatLng != null)
                            IconButton(
                              icon: const Icon(
                                Icons.map_outlined,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                              tooltip: "Lihat di Peta",
                              onPressed: () {
                                _tabController.animateTo(0);
                                _mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(target: areaLatLng, zoom: 16.0),
                                  ),
                                );
                              },
                            ),
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
    );
  }
}
