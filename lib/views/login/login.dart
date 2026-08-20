import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/bottom_nav.dart';
import 'package:fodos/views/login/halaman_pendaftaran.dart';
import 'package:fodos/constants/App_images.dart';

class HalamanLoginTugas12 extends StatefulWidget {
  const HalamanLoginTugas12({super.key});

  @override
  State<HalamanLoginTugas12> createState() => _HalamanLoginTugas12State();
}

class _HalamanLoginTugas12State extends State<HalamanLoginTugas12> {
  final _formKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  bool _isLoading = false;

  final TextEditingController emailC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();

  @override
  void dispose() {
    emailC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  void loginPengguna() async {
    final user = emailC.text.trim();
    final pass = passwordC.text;
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi semua field!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pengguna = await DBHelper().loginUser(user, pass);

      if (!mounted) return;

      if (pengguna != null) {
        await PreferenceHandler.setLogin(true);
        await PreferenceHandler.setUserEmail(pengguna.email);
        if (!mounted) return;

        context.pushAndRemoveAll(const BottomNavTugas12());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login gagal! Email atau Password salah.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Logo Section
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset(
                          AppImages.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title & Subtitle
                  Text(
                    "FODOS",
                    textAlign: TextAlign.center,
                    style: AppTextstyle.heading1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Selamatkan Makanan, Selamatkan Bumi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email Input Field
                  Text(
                    "Email",
                    style: AppTextstyle.heading2.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Masukkan Email Anda",
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email Wajib Diisi!";
                      }
                      if (!value.contains("@")) {
                        return "Email tidak valid!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input Field
                  Text(
                    "Password",
                    style: AppTextstyle.heading2.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordC,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      hintText: "Masukkan Password",
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password Wajib Diisi!";
                      }
                      if (value.length < 8) {
                        return "Password Minimal 8 Karakter!";
                      }
                      return null;
                    },
                  ),

                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Fitur Lupa Kata Sandi belum tersedia."),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                      child: Text(
                        "Lupa Kata Sandi?",
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Submit Button
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
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                loginPengguna();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Social Login Separator
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "ATAU MASUK DENGAN",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Login Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          iconPath: "assets/images/google.png",
                          label: "Google",
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSocialButton(
                          iconPath: "assets/images/fbIcon.png",
                          label: "Facebook",
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Belum punya akun? ",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push(const HalamanPendaftaranFodos());
                        },
                        child: Text(
                          "Daftar Sekarang",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_circle,
                  color: AppColors.textGrey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
