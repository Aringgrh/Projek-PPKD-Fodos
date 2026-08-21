import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';

Widget displayProduk({
  required String image,
  required String namaMakanan,
  required String namaToko,
  required String sisaPorsi,
  required String pickUp,
  String harga = "Rp 15.000",
  VoidCallback? onTap,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Distance Badge
            Stack(
              children: [
                Container(
                  height: 165,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ],
            ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Stock Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          namaMakanan,
                          style: AppTextstyle.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$sisaPorsi porsi tersisa",
                          style: const TextStyle(
                            color: AppColors.badgeText,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Store Name
                  Text(namaToko, style: AppTextstyle.namaToko),
                  const SizedBox(height: 8),

                  // Price Row
                  Row(children: [Text(harga, style: AppTextstyle.harga)]),
                  const SizedBox(height: 10),

                  // Divider
                  Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),

                  // Pickup Schedule Row
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        "PICKUP: $pickUp",
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
