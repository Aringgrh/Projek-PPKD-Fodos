import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/views/profile/informasi_pribadi.dart';
import 'package:fodos/views/profile/profil_alamat.dart';
import 'package:fodos/views/profile/profil_keamanan.dart';
import 'package:fodos/views/profile/profil_metode_pembayaran.dart';
import 'package:fodos/views/profile/profil_tentang_aplikasi.dart';
import 'package:fodos/views/profile/widget_profile.dart';

class ProfileTugas12 extends StatefulWidget {
  const ProfileTugas12({super.key});

  @override
  State<ProfileTugas12> createState() => _ProfileTugas12State();
}

class _ProfileTugas12State extends State<ProfileTugas12> {
  String _userName = 'ariii';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final email = PreferenceHandler.getUserEmail();
      if (email != null && email.isNotEmpty) {
        final user = await DBHelper().getUserByEmail(email);
        if (user != null && mounted) {
          setState(() {
            _userName = user.nama;
          });
        }
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
            Icon(Icons.location_on, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              "FODOS",
              style: TextStyle(
                color: AppColors.primary,
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
                        context.push(const MetodePembayaranProfile());
                      },
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF404941),
                        size: 22,
                      ),
                      title: "Metode Pembayaran",
                      subtitle: "Gopay, ShopeePay, Kartu Kredit",
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
                        await PreferenceHandler.logOut();
                        if (context.mounted) {
                          context.push(const HalamanLoginFodos());
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
