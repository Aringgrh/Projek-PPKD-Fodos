import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_images.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

Widget carouselGambar() {
  final List<Map<String, String>> banners = [
    {
      "image": AppImages.carausel1,
      "title": "Darurat\nBantu Korban Gempa",
      "subtitle": "Bantu Warga Terdampak Gempa di NTT & Sekitarnya",
      "button": "Donasi",
    },
    {
      "image": AppImages.carausel2,
      "title": "Air Bersih \nUntuk Warga",
      "subtitle": "Bantuan Air Bersih Untuk Warga Sumbar yang Terdampak ",
      "button": "Donasi",
    },
  ];
  final Uri url = Uri.parse('https://kitabisa.com/');

  Future<void> launchCarouselUrl() async {
    if (!await launchUrl(url)) {
      throw Exception('Tidak dapat membuka $url');
    }
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: CarouselSlider(
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(banner["image"]!, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.88),
                              AppColors.primary.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner["title"]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner["subtitle"]!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: launchCarouselUrl,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  banner["button"]!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
      options: CarouselOptions(
        height: 165,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.92,
        enlargeCenterPage: true,
      ),
    ),
  );
}
