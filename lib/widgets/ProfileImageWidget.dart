import 'package:flutter/material.dart';
import 'package:rusa/screens/ProfileImageViewScreen.dart';

class ProfileImageWidget extends StatelessWidget {
  final String imagePath;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final VoidCallback? onTap;
  final String? userName;

  const ProfileImageWidget({
    super.key,
    required this.imagePath,
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
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: size - 4, // Ajuster pour la bordure
            height: size - 4, // Ajuster pour la bordure
          ),
        ),
      ),
    );
  }
}
