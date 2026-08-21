import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';

IconButton iconTitleHome({required Widget icon}) {
  return IconButton(onPressed: () {}, icon: icon);
}

Widget pilihanKategori({
  double? width,
  IconData icon = Icons.fastfood,
  String text = 'All',
  bool isSelected = false,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 38,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? null
            : Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFF404941),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF404941),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}


