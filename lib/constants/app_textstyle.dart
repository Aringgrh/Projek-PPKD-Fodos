import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF004625);
  static const Color secondary = Color(0xFF006D40);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF191C1D);
  static const Color textGrey = Color(0xFF718096);
  static const Color border = Color(0xFFE1E3E4);
  static const Color badgeBg = Color(0xFFFFDBD0);
  static const Color badgeText = Color(0xFF832600);
}

class AppTextstyle {
  AppTextstyle._();
  static const heading1 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: AppColors.textDark,
  );
  static const heading2 = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textDark,
  );
  static const sectionTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textDark,
  );
  static const cardTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.textDark,
  );
  static const namaToko = TextStyle(
    fontSize: 11,
    color: AppColors.textGrey,
  );
  static const harga = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
    color: AppColors.secondary,
  );
  static const hargaCoret = TextStyle(
    fontSize: 11,
    color: AppColors.textGrey,
    decoration: TextDecoration.lineThrough,
  );
}

