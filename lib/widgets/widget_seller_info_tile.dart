import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';

Widget widgetSellerInfoTile({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
