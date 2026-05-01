import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileImageViewScreen extends StatelessWidget {
  static const String _defaultAssetImage = 'assets/images/profil.jpg';
  final String imagePath;
  final String? imageUrl;
  final String? userName;

  const ProfileImageViewScreen({
    super.key,
    required this.imagePath,
    this.imageUrl,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userName ?? 'Utilisateur',
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Partager l'image
            },
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image agrandie avec animation
            Hero(
              tag: 'profile_image',
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildImage(),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton modifier
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Retourner avec une option de modification
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

                // Bouton supprimer
                OutlinedButton.icon(
                  onPressed: () {
                    // Action de suppression
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final safeAssetPath = imagePath.trim().isNotEmpty
        ? imagePath
        : _defaultAssetImage;
    final raw = imageUrl?.trim() ?? '';
    if (raw.isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return Image.network(
          raw,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset(safeAssetPath, fit: BoxFit.cover),
        );
      }

      final bytes = _decodeBase64Image(raw);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      }
    }

    return Image.asset(safeAssetPath, fit: BoxFit.cover);
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
