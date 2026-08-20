import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/model/login_user_model.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/views/home/widget_method.dart';
import 'package:fodos/constants/App_images.dart';

class HalamanPendaftaranFodos extends StatefulWidget {
  const HalamanPendaftaranFodos({super.key});

  @override
  State<HalamanPendaftaranFodos> createState() =>
      _HalamanPendaftaranFodosState();
}

class _HalamanPendaftaranFodosState extends State<HalamanPendaftaranFodos> {
  bool hide = true;
  TextEditingController namaC = TextEditingController();
  TextEditingController nomorC = TextEditingController();
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();
  TextEditingController konfirmC = TextEditingController();
  TextEditingController alamatC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  void pendaftaranPengguna() async {
    final nama = namaC.text;
    final nomor = nomorC.text;
    final email = emailC.text.trim();
    final pass = passC.text;
    final alamat = alamatC.text;

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

    final pengguna = UserModelLoginSQL(
      nama: nama,
      nomorhp: nomor,
      email: email,
      password: pass,
      alamat: alamat,
    );

    bool success = await DBHelper().registerUser(pengguna);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat')));

      context.push(HalamanLoginFodos());
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sudah terdaftar!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          height: 1200,
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: BoxBorder.all(color: Colors.black),
          ),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(75),
                        ),
                        child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                  Text(
                    "Buat Akun Baru",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  judulTextfield("Nama Lengkap"),
                  SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nama Anda",
                    kontroller: namaC,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Nama Wajib Di isi";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  judulTextfield("HandPhone"),
                  SizedBox(height: 5),
                  textInputan(
                    "Masukkan Nomor HandPhone",
                    kontroller: nomorC,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Nomor Wajib Di isi";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  judulTextfield("Email"),
                  SizedBox(height: 5),
                  textInputan(
                    "Masukkan Email",
                    kontroller: emailC,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email Wajib Di isi";
                      } else if (!value.contains("@")) {
                        return "Email Tidak Valid";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
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
                        return "Password Wajib Di isi";
                      } else if (value.length < 8) {
                        return "Kata Sandi Harus Lebih Dari 8 Karakter";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),
                  judulTextfield("Konfirmasi Password"),
                  SizedBox(height: 5),
                  passField(
                    obscureText: hide,
                    hintText: "Masukkan Konfirmasi Password",
                    controller: konfirmC,
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
                        return "Password Wajib Di isi";
                      } else if (value != passC.text) {
                        return "Pasword Tidak valid!";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  judulTextfield("Alamat"),
                  SizedBox(height: 5),
                  textInputan(
                    "Masukkan Alamat Anda",
                    kontroller: alamatC,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Alamat Wajib Di isi";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    height: 40,
                    width: 400,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          AppColors.secondary,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            pendaftaranPengguna();
                          });
                        }
                      },
                      child: Text(
                        "Daftar",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sudah punya akun?"),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            context.pop(HalamanLoginFodos());
                          });
                        },
                        child: Text(
                          "Masuk",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ],
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
