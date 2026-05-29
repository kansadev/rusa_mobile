import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rusa/screens/ProfileImageViewScreen.dart';

class ProfileImageWidget extends StatelessWidget {
  final String imagePath;
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final VoidCallback? onTap;
  final String? userName;

  const ProfileImageWidget({
    super.key,
    required this.imagePath,
    this.imageUrl,
    this.size = 50.0,
    this.borderWidth = 2.0,
    this.borderColor = const Color(0xFF00E676),
    this.onTap,
    this.userName,
  });

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
        child: ClipOval(child: _buildProfileImage()),
      ),
    );
  }

  Widget _buildProfileImage() {
    final rawImage = imageUrl?.trim() ?? '';
    final hasRemoteImage = rawImage.isNotEmpty;

    if (hasRemoteImage) {
      if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
        return Image.network(
          rawImage,
          fit: BoxFit.cover,
          width: size - 4,
          height: size - 4,
          errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
        );
      }

      final bytes = _decodeBase64Image(rawImage);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size - 4,
          height: size - 4,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
        );
      }

      return Image.network(
        rawImage,
        fit: BoxFit.cover,
        width: size - 4,
        height: size - 4,
        errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
      );
    }

    final assetPath = imagePath.trim();
    if (assetPath.isNotEmpty && !assetPath.startsWith('http')) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: size - 4,
        height: size - 4,
        errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
      );
    }

    return _defaultAvatarIcon();
  }

  Widget _defaultAvatarIcon() {
    return const ColoredBox(
      color: Color(0xFF1A1A1A),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF00E676),
          size: 28,
        ),
      ),
    );
  }

  Uint8List? _decodeBase64Image(String input) {
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
