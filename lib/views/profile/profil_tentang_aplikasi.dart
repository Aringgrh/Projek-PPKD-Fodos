import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/widgets/widget_tentang_aplikasi.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilTentangAplikasi extends StatefulWidget {
  const ProfilTentangAplikasi({super.key});

  @override
  State<ProfilTentangAplikasi> createState() => _ProfilTentangAplikasiState();
}

class _ProfilTentangAplikasiState extends State<ProfilTentangAplikasi> {
  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tautan $urlString tidak dapat dibuka."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka tautan: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDetailDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
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
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tentang Aplikasi",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Aplikasi
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/logoo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.eco_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "FODOS",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Food Rescue & Zero Waste Platform",
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Versi 1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Misi Kami
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Misi Kami",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "FODOS adalah platform yang menjembatani kelebihan makanan dari bisnis dengan konsumen yang peduli lingkungan. Kami membantu mengurangi limbah makanan sambil menyediakan akses makanan berkualitas dengan harga terjangkau.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Syarat & Ketentuan & Kebijakan Privasi
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildLinkTile(
                      icon: Icons.gavel_rounded,
                      title: "Syarat & Ketentuan",
                      onTap: () => _showDetailDialog(
                        "Syarat & Ketentuan",
                        "Selamat datang di FODOS!\n\n"
                            "1. Penggunaan Layanan:\n"
                            "Dengan menggunakan aplikasi ini, Anda setuju untuk mengambil makanan pesanan sesuai jadwal yang telah ditentukan oleh mitra merchant.\n\n"
                            "2. Kualitas Makanan:\n"
                            "Mitra merchant bertanggung jawab menjaga kelayakan dan kebersihan makanan surplus yang dijual.\n\n"
                            "3. Pembatalan:\n"
                            "Pesanan yang sudah diproses tidak dapat dibatalkan secara sepihak untuk menjaga komitmen pengurangan limbah makanan.",
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFEEEEEE),
                    ),
                    buildLinkTile(
                      icon: Icons.shield_outlined,
                      title: "Kebijakan Privasi",
                      onTap: () => _showDetailDialog(
                        "Kebijakan Privasi",
                        "Kebijakan Privasi FODOS:\n\n"
                            "1. Pengumpulan Data:\n"
                            "Kami mengumpulkan informasi akun seperti nama, email, dan alamat untuk memberikan layanan terbaik.\n\n"
                            "2. Keamanan Data:\n"
                            "Data pengguna disimpan secara aman dan terenkripsi. Kami tidak membagikan data pribadi Anda kepada pihak ketiga tanpa persetujuan.\n\n"
                            "3. Hak Pengguna:\n"
                            "Anda berhak memperbarui atau menghapus informasi pribadi Anda kapan saja melalui menu pengaturan akun.",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Ikuti Kami (Instagram & Facebook)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Ikuti Kami",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instagram Button
                        buildSocialCard(
                          label: "Instagram",
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF833AB4),
                              Color(0xFFFD1D1D),
                              Color(0xFFF77737),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.camera_alt_rounded,
                          onTap: () => _launchUrl("https://instagram.com"),
                        ),
                        const SizedBox(width: 16),
                        // Facebook Button
                        buildSocialCard(
                          label: "Facebook",
                          color: const Color(0xFF1877F2),
                          icon: Icons.facebook,
                          onTap: () => _launchUrl("https://facebook.com"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Footer
              Column(
                children: [
                  const Text(
                    "FODOS © 2024. All rights reserved.",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
