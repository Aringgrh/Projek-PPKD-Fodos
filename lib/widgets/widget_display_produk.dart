import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/widgets/app_image_loader.dart';

Widget _buildProductImage(String image) {
  return AppImageLoader(
    imageUrl: image,
    width: double.infinity,
    height: 165,
    fit: BoxFit.cover,
  );
}

Widget displayProduk({
  required String image,
  required String namaMakanan,
  required String namaToko,
  required String sisaPorsi,
  String? pickUp,
  String? alamat,
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
            // Image Container
            Stack(children: [_buildProductImage(image)]),

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),

                  // Store Address Row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (alamat != null && alamat.trim().isNotEmpty)
                              ? alamat
                              : (pickUp != null && pickUp.trim().isNotEmpty)
                                  ? pickUp
                                  : "Alamat toko belum diatur",
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
