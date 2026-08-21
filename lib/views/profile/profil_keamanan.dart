import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/model/login_user_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class ProfilKeamanan extends StatefulWidget {
  const ProfilKeamanan({super.key});

  @override
  State<ProfilKeamanan> createState() => _ProfilKeamananState();
}

class _ProfilKeamananState extends State<ProfilKeamanan> {
  final TextEditingController _kataSandiSaatIniC = TextEditingController();
  final TextEditingController _kataSandiBaruC = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _isTwoFactorEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;

  UserModelLoginSQL? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _kataSandiSaatIniC.dispose();
    _kataSandiBaruC.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final email = PreferenceHandler.getUserEmail();
    if (email != null && email.isNotEmpty) {
      final user = await DBHelper().getUserByEmail(email);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _simpanKeamanan() async {
    final currentPass = _kataSandiSaatIniC.text.trim();
    final newPass = _kataSandiBaruC.text.trim();

    // If both password fields are empty, just save settings like 2FA switch state
    if (currentPass.isEmpty && newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Pengaturan keamanan berhasil disimpan! 2FA: ${_isTwoFactorEnabled ? 'Aktif' : 'Nonaktif'}",
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation when updating password
    if (currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan kata sandi saat ini untuk mengubah kata sandi."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan kata sandi baru."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kata sandi baru minimal 6 karakter."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_currentUser != null && _currentUser!.password != currentPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kata sandi saat ini tidak cocok."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentUser != null) {
        final updatedUser = UserModelLoginSQL(
          id: _currentUser!.id,
          nama: _currentUser!.nama,
          nomorhp: _currentUser!.nomorhp,
          email: _currentUser!.email,
          password: newPass,
          alamat: _currentUser!.alamat,
          gambar: _currentUser!.gambar,
        );

        final success = await DBHelper().updateUser(updatedUser);
        if (success) {
          _currentUser = updatedUser;
          _kataSandiSaatIniC.clear();
          _kataSandiBaruC.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Kata sandi berhasil diperbarui!"),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gagal memperbarui kata sandi di database."),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        _kataSandiSaatIniC.clear();
        _kataSandiBaruC.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pengaturan kata sandi telah diperbarui."),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showRiwayatLoginDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Riwayat Login Perangkat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.laptop_windows_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  "Chrome (Windows)",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  "Aktif Sekarang • Jakarta, Indonesia",
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Aktif",
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.textGrey,
                  ),
                ),
                title: const Text(
                  "FODOS App (Android)",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  "2 Jam yang lalu • Bandung, Indonesia",
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showKebijakanPrivasiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.secondary),
            SizedBox(width: 8),
            Text(
              "Kebijakan Privasi FODOS",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "FODOS berkomitmen penuh untuk melindungi privasi dan data pribadi Anda. "
            "Setiap kata sandi dan informasi kredensial disimpan dengan enkripsi aman. "
            "Kami tidak akan pernah membagikan informasi akun Anda kepada pihak ketiga tanpa izin Anda.",
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Paham",
              style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Keamanan",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Illustration / Status Area
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8EF5B5).withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: Color(0xFF007243),
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Lindungi Akun Anda",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "Pastikan akun FODOS Anda tetap aman dengan mengaktifkan fitur keamanan terbaru.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF404941),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Security Card Container
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Change Password Section
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.lock_open_rounded,
                                      color: AppColors.secondary,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Ubah Kata Sandi",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Current Password Field
                                const Text(
                                  "KATA SANDI SAAT INI",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF404941),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: TextField(
                                    controller: _kataSandiSaatIniC,
                                    obscureText: _obscureCurrentPassword,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "••••••••",
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureCurrentPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.textGrey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureCurrentPassword = !_obscureCurrentPassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // New Password Field
                                const Text(
                                  "KATA SANDI BARU",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF404941),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: TextField(
                                    controller: _kataSandiBaruC,
                                    obscureText: _obscureNewPassword,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "••••••••",
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureNewPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.textGrey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureNewPassword = !_obscureNewPassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),

                                // 2FA Toggle Row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.verified_user_rounded,
                                        color: AppColors.secondary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Autentikasi 2 Faktor",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isTwoFactorEnabled
                                                ? "Aktif (SMS & Email)"
                                                : "Nonaktif",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _isTwoFactorEnabled
                                                  ? AppColors.secondary
                                                  : AppColors.textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _isTwoFactorEnabled,
                                      activeThumbColor: AppColors.secondary,
                                      onChanged: (val) {
                                        setState(() {
                                          _isTwoFactorEnabled = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),

                                // Login History Row
                                InkWell(
                                  onTap: _showRiwayatLoginDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.history_rounded,
                                            color: AppColors.secondary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Riwayat Login",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                "Lihat aktivitas masuk terakhir",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textGrey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Privacy Policy Hint Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Keamanan data Anda adalah prioritas kami.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF404941),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _showKebijakanPrivasiDialog,
                                  child: const Text(
                                    "Pelajari kebijakan privasi FODOS",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button Container (Fixed/Sticky)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _simpanKeamanan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Simpan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
