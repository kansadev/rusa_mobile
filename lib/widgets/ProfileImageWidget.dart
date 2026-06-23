import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rusa/screens/ProfileImageViewScreen.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final VoidCallback? onTap;
  final String? userName;

  const ProfileImageWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 50.0,
    this.borderWidth = 2.0,
    this.borderColor = const Color(0xFF00E676),
    this.onTap,
    this.userName,
  });

  /// Construit l'image de profil (réseau, base64, asset local ou avatar par défaut).
  static Widget buildProfileImage({
    String? imagePath,
    String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final rawImage = imageUrl?.trim() ?? '';
    if (rawImage.isNotEmpty) {
      if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
        return Image.network(
          rawImage,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              _defaultAvatarIcon(width: width, height: height),
        );
      }

      final bytes = _decodeBase64Image(rawImage);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              _defaultAvatarIcon(width: width, height: height),
        );
      }

      return Image.network(
        rawImage,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            _defaultAvatarIcon(width: width, height: height),
      );
    }

    final assetPath = imagePath?.trim() ?? '';
    if (assetPath.isNotEmpty && !assetPath.startsWith('http')) {
      return Image.asset(
        assetPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            _defaultAvatarIcon(width: width, height: height),
      );
    }

    return _defaultAvatarIcon(width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            // Navigation par défaut vers la visualisation de l'image
            if (userName != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileImageViewScreen(
                    imagePath: imagePath,
                    imageUrl: imageUrl,
                    userName: userName!,
                  ),
                ),
              );
            }
          },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: ClipOval(
          child: buildProfileImage(
            imagePath: imagePath,
            imageUrl: imageUrl,
            width: size - 4,
            height: size - 4,
          ),
        ),
      ),
    );
  }

  static Widget _defaultAvatarIcon({double? width, double? height}) {
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: const Color(0xFF00E676),
          size: (width != null && height != null)
              ? (width < height ? width : height) * 0.56
              : 28,
        ),
      ),
    );
  }

  static Uint8List? _decodeBase64Image(String input) {
    try {
      final cleaned = input.contains('base64,')
          ? input.split('base64,').last
          : input;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}
