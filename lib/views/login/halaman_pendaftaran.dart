import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_images.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/user_model.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/widgets/widget_method.dart';

class HalamanPendaftaranFodos extends StatefulWidget {
  const HalamanPendaftaranFodos({super.key});

  @override
  State<HalamanPendaftaranFodos> createState() =>
      _HalamanPendaftaranFodosState();
}

class _HalamanPendaftaranFodosState extends State<HalamanPendaftaranFodos> {
  bool hide = true;
  bool hideConfirm = true;
  bool isLoading = false;

  final TextEditingController namaC = TextEditingController();
  final TextEditingController nomorC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController konfirmC = TextEditingController();
  final TextEditingController alamatC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    namaC.dispose();
    nomorC.dispose();
    emailC.dispose();
    passC.dispose();
    konfirmC.dispose();
    alamatC.dispose();
    super.dispose();
  }

  Future<void> pendaftaranPengguna() async {
    final nama = namaC.text.trim();
    final nomor = nomorC.text.trim();
    final email = emailC.text.trim();
    final pass = passC.text;
    final alamat = alamatC.text.trim();

    if (nama.isEmpty ||
        nomor.isEmpty ||
        email.isEmpty ||
        pass.isEmpty ||
        alamat.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Buat akun di Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final user = userCredential.user;
      if (user != null) {
        // Update nama display di Firebase Auth
        await user.updateDisplayName(nama);

        // 2. Simpan detail profil ke Firestore
        final newUser = UserModelFirebase(
          uid: user.uid,
          name: nama,
          nomor: nomor,
          email: email,
          alamat: alamat,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat! Silakan masuk.'),
          backgroundColor: Colors.green,
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
        errorMessage = 'Email sudah terdaftar!';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid!';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter)!';
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
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.redAccent,
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
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(75),
                        ),
                        child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Buat Akun Baru",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  judulTextfield("Nama Lengkap"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nama Anda",
                    kontroller: namaC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  judulTextfield("HandPhone"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nomor HandPhone",
                    kontroller: nomorC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nomor Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  judulTextfield("Email"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Email",
                    kontroller: emailC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email Wajib Diisi";
                      } else if (!value.contains("@")) {
                        return "Email Tidak Valid";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  judulTextfield("Password"),
                  const SizedBox(height: 5),
                  passField(
                    obscureText: hide,
                    hintText: "Masukkan Password",
                    controller: passC,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hide = !hide;
                        });
                      },
                      icon: Icon(
                        hide ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password Wajib Diisi";
                      } else if (value.length < 8) {
                        return "Kata Sandi Harus Lebih Dari 8 Karakter";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  judulTextfield("Konfirmasi Password"),
                  const SizedBox(height: 5),
                  passField(
                    obscureText: hideConfirm,
                    hintText: "Masukkan Konfirmasi Password",
                    controller: konfirmC,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                      icon: Icon(
                        hideConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Konfirmasi Password Wajib Diisi";
                      } else if (value != passC.text) {
                        return "Password Tidak Cocok!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  judulTextfield("Alamat"),
                  const SizedBox(height: 5),
                  textInputan(
                    "Masukkan Alamat Anda",
                    kontroller: alamatC,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Alamat Wajib Diisi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                pendaftaranPengguna();
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Daftar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun?"),
                        TextButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.pushReplacement(
                                const HalamanLoginFodos(),
                              );
                            }
                          },
                          child: const Text(
                            "Masuk",
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

