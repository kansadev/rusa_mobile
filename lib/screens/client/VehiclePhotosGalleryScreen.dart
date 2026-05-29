import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aperçu plein écran des photos véhicule (swipe si plusieurs images).
class VehiclePhotosGalleryScreen extends StatefulWidget {
  const VehiclePhotosGalleryScreen({
    super.key,
    required this.memoryImages,
    required this.assetImages,
    this.initialIndex = 0,
    this.title,
  });

  final List<Uint8List> memoryImages;
  final List<String> assetImages;
  final int initialIndex;
  final String? title;

  bool get _useMemory => memoryImages.isNotEmpty;

  int get _count => _useMemory ? memoryImages.length : assetImages.length;

  @override
  State<VehiclePhotosGalleryScreen> createState() =>
      _VehiclePhotosGalleryScreenState();
}

class _VehiclePhotosGalleryScreenState
    extends State<VehiclePhotosGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final max = widget._count;
    final start = max == 0 ? 0 : widget.initialIndex.clamp(0, max - 1);
    _currentIndex = start;
    _pageController = PageController(initialPage: start);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._count == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.title ?? 'Photos du véhicule',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'Aucune image disponible.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title ?? 'Photos du véhicule',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: widget._count,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Hero(
                        tag: 'vehicle_photo_$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget._useMemory
                              ? Image.memory(
                                  widget.memoryImages[index],
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  widget.assetImages[index],
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget._count > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget._count,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 10 : 7,
                    height: _currentIndex == index ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 24),
          Text(
            '${_currentIndex + 1} / ${widget._count}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
