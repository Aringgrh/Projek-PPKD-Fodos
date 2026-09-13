import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/auth_service.dart';
import 'package:fodos/service/seller_service.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/views/profile/informasi_pribadi.dart';
import 'package:fodos/views/profile/profil_alamat.dart';
import 'package:fodos/views/profile/profil_keamanan.dart';
import 'package:fodos/views/profile/profil_tentang_aplikasi.dart';
import 'package:fodos/views/seller/register_store_page.dart';
import 'package:fodos/views/seller/seller_dashboard_page.dart';
import 'package:fodos/widgets/widget_profile.dart';

class ProfileTugas12 extends StatefulWidget {
  const ProfileTugas12({super.key});

  @override
  State<ProfileTugas12> createState() => _ProfileTugas12State();
}

class _ProfileTugas12State extends State<ProfileTugas12> {
  String _userName = 'Pengguna Fodos';
  bool _hasStore = false;
  StoreModel? _userStore;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          if (mounted) setState(() => _userName = user.displayName!);
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null && mounted) {
          final userModel = UserModelFirebase.fromJson(doc.data()!);
          if (userModel.name.isNotEmpty) {
            setState(() {
              _userName = userModel.name;
            });
          }
        }
      }

      // Load store data for seller mode
      final hasStore = await SellerService.hasStore();
      final store = await SellerService.getStore();
      if (mounted) {
        setState(() {
          _hasStore = hasStore;
          _userStore = store;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data in profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            SizedBox(width: 8),
            Text(
              "Pengaturan",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar profile stack
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),

            // Section Pengaturan Akun Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pengaturan Akun",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Card Menu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Toko / Mode Penjual Entry Point
                    _hasStore
                        ? menuProfil(
                            onPressed: () async {
                              await context.push(const SellerDashboardPage());
                              _loadUserData();
                            },
                            leading: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            title: "Toko Saya",
                            subtitle: _userStore != null
                                ? "Dashboard Penjual (${_userStore!.namaToko})"
                                : "Beralih ke Dashboard Penjual",
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "POV Penjual",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : menuProfil(
                            onPressed: () async {
                              await context.push(const RegisterStorePage());
                              _loadUserData();
                            },
                            leading: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            title: "Mulai Berjualan",
                            subtitle: "Buka tokomu & jangkau pembeli Fodos",
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Buka Toko",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    menuProfil(
                      onPressed: () async {
                        await context.push(const InformasiPribadi());
                        _loadUserData();
                      },
                      leading: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF404941),
                        size: 22,
                      ),
                      title: "Informasi Pribadi",
                      subtitle: "Ubah detail profil dan kontak",
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    menuProfil(
                      onPressed: () {
                        context.push(const ProfilAlamat());
                      },
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF404941),
                        size: 22,
                      ),
                      title: "Alamat Tersimpan",
                      subtitle: "Rumah, Kantor, Apartemen",
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    menuProfil(
                      onPressed: () {
                        context.push(const ProfilKeamanan());
                      },
                      leading: const Icon(
                        Icons.security_outlined,
                        color: Color(0xFF404941),
                        size: 22,
                      ),
                      title: "Keamanan & Password",
                      subtitle: "Ubah password, autentikasi 2 faktor",
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    menuProfil(
                      onPressed: () {
                        context.push(const ProfilTentangAplikasi());
                      },
                      leading: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF404941),
                        size: 22,
                      ),
                      title: "Tentang Aplikasi",
                      subtitle: "Versi aplikasi, syarat & ketentuan",
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    menuProfil(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          context.pushAndRemoveAll(const HalamanLoginFodos());
                        }
                      },
                      leading: const Icon(
                        Icons.logout_outlined,
                        color: Colors.red,
                        size: 22,
                      ),
                      title: "Keluar",
                      subtitle: "Keluar dari sesi saat ini",
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
