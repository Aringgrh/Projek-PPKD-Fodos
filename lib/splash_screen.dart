import 'package:flutter/material.dart';
import 'package:fodos/constants/app_images.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/home/bottom_nav.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:lottie/lottie.dart';

class SplashScreenTugas12 extends StatefulWidget {
  const SplashScreenTugas12({super.key});

  @override
  State<SplashScreenTugas12> createState() => _SplashScreenTugas12State();
}

class _SplashScreenTugas12State extends State<SplashScreenTugas12> {
  @override
  void initState() {
    super.initState();
    goToLogin();
  }

  void goToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (PreferenceHandler.isLogin == true) {
      context.pushAndRemoveAll(const BottomNavTugas12());
    } else {
      context.pushAndRemoveAll(const HalamanLoginFodos());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    color: Colors.black,
                    image: DecorationImage(image: AssetImage(AppImages.logo), fit: BoxFit.fill),
                  ),
                ),
                const SizedBox(height: 40),
                Lottie.asset("assets/lottie animations/loading (1).json", height: 160),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
