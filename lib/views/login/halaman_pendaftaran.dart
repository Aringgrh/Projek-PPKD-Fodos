import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_images.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/service/auth_service.dart';
import 'package:fodos/widgets/bottom_nav.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/widgets/widget_login.dart';

class HalamanPendaftaranFodos extends StatefulWidget {
  const HalamanPendaftaranFodos({super.key});

  @override
  State<HalamanPendaftaranFodos> createState() =>
      _HalamanPendaftaranFodosState();
}

class _HalamanPendaftaranFodosState extends State<HalamanPendaftaranFodos> {
  final _formKey = GlobalKey<FormState>();

  bool hide = true;
  bool hideConfirm = true;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool agreeToTerms = false;

  final TextEditingController namaC = TextEditingController();
  final TextEditingController nomorC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController konfirmC = TextEditingController();

  @override
  void dispose() {
    namaC.dispose();
    nomorC.dispose();
    emailC.dispose();
    passC.dispose();
    konfirmC.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Future<void> loginWithGoogle() async {
    if (isGoogleLoading || isLoading) return;
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final userCredential = await AuthService().signInWithGoogle();

      if (userCredential != null && userCredential.user != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pendaftaran Google berhasil! Selamat datang, ${userCredential.user?.displayName ?? "Pengguna"}.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        context.pushAndRemoveAll(const BottomNavTugas12());
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal mendaftar dengan akun Google.';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage =
            'Akun email ini sudah terdaftar dengan metode masuk lain.';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'Gagal terhubung ke jaringan! Periksa koneksi internet Anda.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat pendaftaran Google: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> pendaftaranPengguna() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Harap setujui Syarat & Ketentuan untuk melanjutkan.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final nama = namaC.text.trim();
    final nomor = nomorC.text.trim();
    final email = emailC.text.trim();
    final pass = passC.text;

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().signUpWithEmail(
        name: nama,
        nomor: nomor,
        email: email,
        password: pass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Akun berhasil dibuat! Silakan masuk.')),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.pushReplacement(const HalamanLoginFodos());
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Pendaftaran gagal!';
      if (e.code == 'email-already-in-use') {
        errorMessage =
            'Email sudah terdaftar! Gunakan email lain atau silakan masuk.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid!';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (minimal 8 karakter)!';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'Gagal terhubung ke jaringan! Periksa koneksi internet Anda.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Container
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    "Buat Akun Baru",
                    textAlign: TextAlign.center,
                    style: AppTextstyle.heading1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Mulai langkahmu untuk menyelamatkan makanan berlebih & nikmati berbagai promo hemat bersama FODOS!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Nama Lengkap
                  _buildFieldLabel("Nama Lengkap"),
                  TextFormField(
                    controller: namaC,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    decoration: _inputDecoration(
                      hintText: "Masukkan Nama Lengkap Anda",
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama lengkap wajib diisi!";
                      }
                      if (value.trim().length < 3) {
                        return "Nama minimal 3 karakter!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Nomor Handphone
                  _buildFieldLabel("Nomor WhatsApp / HP"),
                  TextFormField(
                    controller: nomorC,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      hintText: "Contoh: 081234567890",
                      prefixIcon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nomor HP wajib diisi!";
                      }
                      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 9 || digitsOnly.length > 15) {
                        return "Nomor HP tidak valid (9-15 digit)!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 3. Email
                  _buildFieldLabel("Email"),
                  TextFormField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hintText: "nama@email.com",
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email wajib diisi!";
                      }
                      if (!value.contains("@") || !value.contains(".")) {
                        return "Format email tidak valid!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 4. Password
                  _buildFieldLabel("Kata Sandi"),
                  TextFormField(
                    controller: passC,
                    obscureText: hide,
                    decoration: _inputDecoration(
                      hintText: "Minimal 8 karakter",
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            hide = !hide;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Kata sandi wajib diisi!";
                      }
                      if (value.length < 8) {
                        return "Kata sandi minimal 8 karakter!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 6. Konfirmasi Password
                  _buildFieldLabel("Konfirmasi Kata Sandi"),
                  TextFormField(
                    controller: konfirmC,
                    obscureText: hideConfirm,
                    decoration: _inputDecoration(
                      hintText: "Ulangi kata sandi Anda",
                      prefixIcon: Icons.lock_reset_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            hideConfirm = !hideConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Konfirmasi kata sandi wajib diisi!";
                      }
                      if (value != passC.text) {
                        return "Kata sandi tidak cocok!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms & Condition Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: agreeToTerms,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (val) {
                            setState(() {
                              agreeToTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              agreeToTerms = !agreeToTerms;
                            });
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textDark,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(text: "Saya menyetujui "),
                                TextSpan(
                                  text: "Syarat & Ketentuan",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: " serta "),
                                TextSpan(
                                  text: "Kebijakan Privasi",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: " FODOS."),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading ? null : pendaftaranPengguna,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Daftar Sekarang",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Social Login Separator
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.border, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "ATAU DAFTAR DENGAN",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.border, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(
                        child: buildSocialHButton(
                          iconPath: "assets/images/googleIcon.png",
                          label: "Google",
                          isLoading: isGoogleLoading,
                          onTap: loginWithGoogle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: buildSocialHButton(
                          iconPath: "assets/images/fbIcon.png",
                          label: "Facebook",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Pendaftaran via Facebook belum tersedia.",
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Back to Login Link
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Sudah punya akun? ",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.pushReplacement(
                                const HalamanLoginFodos(),
                              );
                            }
                          },
                          child: const Text(
                            "Masuk Sekarang",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
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
        ),
      ),
    );
  }
}
