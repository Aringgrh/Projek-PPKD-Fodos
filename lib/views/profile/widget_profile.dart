import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';

Widget buildInputField({
  required String label,
  required IconData icon,
  required TextEditingController controller,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  Function(String)? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF191C1D),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget menuProfil({
  required VoidCallback onPressed,
  required Widget leading,
  required String title,
  required String subtitle,
  Widget? trailing,
  bool isDestructive = false,
}) {
  return InkWell(
    onTap: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDestructive
                  ? const Color(0xFFFFDAD6).withValues(alpha: 0.4)
                  : const Color(0xFFEDEEEF),
            ),
            child: leading,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? Colors.red : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDestructive ? Colors.red.withValues(alpha: 0.6) : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    ),
  );
}
