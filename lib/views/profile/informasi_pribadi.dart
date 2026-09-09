import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/models/models.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/profile/profil_keamanan.dart';
import 'package:fodos/widgets/widget_informasi_pribadi.dart';

class InformasiPribadi extends StatefulWidget {
  const InformasiPribadi({super.key});

  @override
  State<InformasiPribadi> createState() => _InformasiPribadiState();
}

class _InformasiPribadiState extends State<InformasiPribadi> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController nomorC = TextEditingController();
  final TextEditingController domisiliC = TextEditingController();

  UserModelFirebase? currentUser;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    namaC.dispose();
    emailC.dispose();
    nomorC.dispose();
    domisiliC.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          currentUser = UserModelFirebase.fromJson(doc.data()!);
          namaC.text = currentUser!.name;
          emailC.text = currentUser!.email.isNotEmpty ? currentUser!.email : (user.email ?? '');
          nomorC.text = currentUser!.nomor;
          domisiliC.text = currentUser!.alamat;
        } else {
          namaC.text = user.displayName ?? '';
          emailC.text = user.email ?? (PreferenceHandler.getUserEmail() ?? '');
        }
      } else {
        emailC.text = PreferenceHandler.getUserEmail() ?? '';
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      isSaving = true;
    });

    final newNama = namaC.text.trim();
    final newEmail = emailC.text.trim();
    final newNomor = nomorC.text.trim();
    final newDomisili = domisiliC.text.trim();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updatedUser = UserModelFirebase(
          uid: user.uid,
          name: newNama,
          nomor: newNomor,
          email: newEmail,
          alamat: newDomisili,
          createdAt: currentUser?.createdAt ?? DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updatedUser.toMap(), SetOptions(merge: true));

        await user.updateDisplayName(newNama);
        await PreferenceHandler.setUserEmail(newEmail);
        currentUser = updatedUser;
      }
    } catch (e) {
      debugPrint("Error saving user data: $e");
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi pribadi berhasil disimpan!'),
          backgroundColor: Color(0xFF006D40),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Informasi Pribadi",
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // Profile Photo Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEDEEEF),
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person, size: 70, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          namaC.text.isEmpty ? "Profil Pengguna" : namaC.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Lengkapi profil untuk pengalaman terbaik",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Form Fields Section
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Lengkap
                        buildInputField(
                          label: "NAMA LENGKAP",
                          icon: Icons.person_outline,
                          controller: namaC,
                          hintText: "Masukkan nama lengkap",
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),

                        // Alamat Email
                        buildInputField(
                          label: "ALAMAT EMAIL",
                          icon: Icons.mail_outline,
                          controller: emailC,
                          hintText: "Masukkan email",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        // Nomor Telepon
                        buildInputField(
                          label: "NOMOR TELEPON",
                          icon: Icons.phone_outlined,
                          controller: nomorC,
                          hintText: "Masukkan nomor telepon",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 18),

                        // Domisili / Alamat
                        buildInputField(
                          label: "DOMISILI / ALAMAT",
                          icon: Icons.location_on_outlined,
                          controller: domisiliC,
                          hintText: "Masukkan domisili / alamat",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Additional Options Section
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: const Icon(Icons.lock_outline, color: Color(0xFF404941)),
                            title: const Text(
                              "Ubah Kata Sandi",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF191C1D),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              context.push(ProfilKeamanan());
                            },
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF404941),
                            ),
                            title: const Text(
                              "Verifikasi Akun",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF191C1D),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur Verifikasi Akun dipilih')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

      // Bottom Action Area
      bottomSheet: isLoading
          ? null
          : Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    onPressed: isSaving ? null : _saveChanges,
                    child: isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Menyimpan...",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : const Text(
                            "Simpan Perubahan",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
