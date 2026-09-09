import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class AppImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImageLoader({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
    this.placeholder,
    this.errorWidget,
  });

  /// Helper untuk membersihkan dan mentransformasikan format link gambar
  static String cleanUrl(String raw) {
    var str = raw.trim();
    // Hilangkan kutip jika ada (misal: "https://..." atau 'https://...')
    if ((str.startsWith('"') && str.endsWith('"')) ||
        (str.startsWith("'") && str.endsWith("'"))) {
      str = str.substring(1, str.length - 1).trim();
    }

    // Ubah link Google Drive preview menjadi direct image link
    if (str.contains('drive.google.com/file/d/')) {
      final regExp = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(str);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        str = 'https://drive.google.com/uc?export=view&id=$id';
      }
    } else if (str.contains('drive.google.com/open?id=')) {
      final id = str.split('id=').last.split('&').first;
      str = 'https://drive.google.com/uc?export=view&id=$id';
    }

    // Ubah link Dropbox preview menjadi raw image
    if (str.contains('dropbox.com') && str.contains('dl=0')) {
      str = str.replaceAll('dl=0', 'raw=1');
    }

    return str;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = cleanUrl(imageUrl);

    Widget imageWidget;

    if (cleaned.isEmpty) {
      imageWidget = errorWidget ?? _buildDefaultError();
    } else if (cleaned.startsWith('data:image') ||
        (cleaned.length > 150 &&
            !cleaned.startsWith('http') &&
            !cleaned.startsWith('assets/'))) {
      // 1. Format Base64 / Memory Image
      try {
        final base64Str =
            cleaned.contains(',') ? cleaned.split(',').last : cleaned;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ [AppImageLoader] Gagal decode Base64: $error');
            return errorWidget ?? _buildDefaultError();
          },
        );
      } catch (e) {
        debugPrint('⚠️ [AppImageLoader] Error parsing Base64: $e');
        imageWidget = errorWidget ?? _buildDefaultError();
      }
    } else if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      // 2. Format URL Jaringan (Firebase Storage / Web Image)
      imageWidget = Image.network(
        cleaned,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '⚠️ [AppImageLoader] Gagal memuat Network Image: $cleaned\nError: $error',
          );
          return errorWidget ?? _buildDefaultError();
        },
      );
    } else if (cleaned.startsWith('file://') ||
        cleaned.startsWith('/') ||
        (cleaned.length > 2 && cleaned[1] == ':')) {
      // 3. Format File Penyimpanan Lokal Perangkat
      final filePath = cleaned.startsWith('file://')
          ? cleaned.replaceFirst('file://', '')
          : cleaned;
      final file = File(filePath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ [AppImageLoader] Gagal load File: $filePath ($error)');
            return errorWidget ?? _buildDefaultError();
          },
        );
      } else {
        debugPrint('⚠️ [AppImageLoader] File tidak ditemukan: $filePath');
        imageWidget = errorWidget ?? _buildDefaultError();
      }
    } else {
      // 4. Format Asset Lokal
      final assetPath = cleaned.startsWith('assets/')
          ? cleaned
          : (cleaned.startsWith('images/')
              ? 'assets/$cleaned'
              : 'assets/images/$cleaned');

      imageWidget = Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '⚠️ [AppImageLoader] Asset tidak ditemukan: $assetPath ($error)',
          );
          return errorWidget ?? _buildDefaultError();
        },
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
