import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/service/preferencehandler.dart';

class HalamanPilihLokasi extends StatefulWidget {
  final bool openDirectlyToMap;

  const HalamanPilihLokasi({super.key, this.openDirectlyToMap = false});

  @override
  State<HalamanPilihLokasi> createState() => _HalamanPilihLokasiState();
}

class _HalamanPilihLokasiState extends State<HalamanPilihLokasi> {
  final TextEditingController _mapSearchController = TextEditingController();
  final Geocoding _geocoding = Geocoding();

  bool _isDetectingLocation = false;

  // Google Maps State
  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(
    -6.2088,
    106.8456,
  ); // Jakarta Pusat
  LatLng _currentMapPosition = _initialPosition;
  String _mapAddressTitle = "Memuat lokasi...";
  String _mapAddressDetail = "Jakarta, Indonesia";
  bool _isMapGeocoding = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _reverseGeocodePosition(_initialPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptLocationPermission();
    });
  }

  Future<void> _checkAndPromptLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showEnableGpsDialog();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        _showPermissionRequestDialog();
      }
    } else if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionDeniedForeverDialog();
      }
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _detectCurrentLocation(moveToMap: true);
    }
  }

  void _showEnableGpsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text(
              "Layanan GPS Mati",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "GPS perangkat Anda belum aktif. Aktifkan GPS untuk mendeteksi lokasi Anda di peta secara presisi.",
          style: TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Nanti Saja", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text("Aktifkan GPS"),
          ),
        ],
      ),
    );
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.near_me_rounded, color: AppColors.secondary, size: 24),
            SizedBox(width: 10),
            Text(
              "Izin Akses Lokasi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Fodos membutuhkan izin akses lokasi Anda untuk menampilkan posisi presisi pada peta dan mempermudah pengiriman pesanan.",
          style: TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              LocationPermission p = await Geolocator.requestPermission();
              if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
                _detectCurrentLocation(moveToMap: true);
              }
            },
            child: const Text("Izinkan Lokasi"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              "Izin Lokasi Ditolak",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Izin lokasi ditolak secara permanen. Buka Pengaturan Aplikasi untuk mengizinkan akses lokasi.",
          style: TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapSearchController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // --- Real Reverse Geocoding with Graceful Fallback ---
  Future<void> _reverseGeocodePosition(LatLng target) async {
    if (!mounted) return;
    setState(() {
      _isMapGeocoding = true;
    });

    try {
      final placemarks = await _geocoding
          .placemarkFromCoordinates(target.latitude, target.longitude)
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
  Future<void> _detectCurrentLocation({bool moveToMap = true}) async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showEnableGpsDialog();
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showPermissionRequestDialog();
          }
          setState(() => _isDetectingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionDeniedForeverDialog();
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      }

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLatLng, zoom: 16.5),
          ),
        );
        _reverseGeocodePosition(currentLatLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mendeteksi lokasi GPS: ${e.toString()}"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  Future<void> _selectLocation(
    String title, {
    String detail = "Sekitar kamu",
  }) async {
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

    Navigator.pop(context, {'title': title, 'detail': detail});
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
          "Pilih Lokasi Anda",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildInteractiveMapView(),
    );
  }

  // =========================================================================
  // GOOGLE MAPS INTERACTIVE PICKER VIEW
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

        // 2. Center Fixed Pin
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 38),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating tooltip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.touch_app,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Geser peta ke titik pas",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
                    hintStyle: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    suffixIcon: _mapSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textGrey,
                              size: 18,
                            ),
                            onPressed: () {
                              _mapSearchController.clear();
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            onPressed: () => _searchAndAnimateToLocation(
                              _mapSearchController.text,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
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
                    _buildMapQuickChip(
                      "Menteng",
                      const LatLng(-6.1931, 106.8236),
                    ),
                    _buildMapQuickChip("PIK", const LatLng(-6.1118, 106.7408)),
                    _buildMapQuickChip(
                      "Kemang",
                      const LatLng(-6.2738, 106.8155),
                    ),
                    _buildMapQuickChip(
                      "Kelapa Gading",
                      const LatLng(-6.1601, 106.9080),
                    ),
                    _buildMapQuickChip(
                      "Dago Bandung",
                      const LatLng(-6.8890, 107.6160),
                    ),
                    _buildMapQuickChip(
                      "Surabaya",
                      const LatLng(-7.2600, 112.7483),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. Floating Action Controls (GPS & Zoom)
        Positioned(
          right: 16,
          bottom: 180,
          child: Column(
            children: [
              // Current GPS Location Button
              FloatingActionButton.small(
                heroTag: 'gps_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
                elevation: 3,
                onPressed: _isDetectingLocation
                    ? null
                    : () => _detectCurrentLocation(moveToMap: true),
                child: _isDetectingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
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

                // Full-width Primary Action Button: "Pilih Lokasi Ini"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _selectLocation(
                        _mapAddressTitle,
                        detail: _mapAddressDetail,
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      "Pilih Lokasi Ini",
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
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
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
              const Icon(
                Icons.location_on,
                size: 13,
                color: AppColors.secondary,
              ),
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
}
