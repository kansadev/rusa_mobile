import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un modèle 3D de la galerie (asset GLB/GLTF ou URL distante).
class Bus3DModel {
  final String src;
  final String name;

  const Bus3DModel({required this.src, required this.name});
}

/// Galerie 3D plein écran : permet de visualiser et de naviguer entre
/// plusieurs modèles de bus (GLB/GLTF) via un carrousel manuel par swipe.
class Bus3DViewScreen extends StatefulWidget {
  final List<Bus3DModel> models;
  final int initialIndex;

  const Bus3DViewScreen({
    super.key,
    this.models = const [
      Bus3DModel(src: 'assets/3d/bus.glb', name: 'Bus standard'),
      Bus3DModel(src: 'assets/3d/torino_byd.glb', name: 'BYD Torino'),
    ],
    this.initialIndex = 0,
  });

  /// Constructeur pratique pour un seul modèle.
  Bus3DViewScreen.single({
    Key? key,
    String modelSrc = 'assets/3d/bus.glb',
    String title = 'Aperçu 3D du bus',
  }) : this(key: key, models: [Bus3DModel(src: modelSrc, name: title)]);

  @override
  State<Bus3DViewScreen> createState() => _Bus3DViewScreenState();
}

class _Bus3DViewScreenState extends State<Bus3DViewScreen> {
  final Flutter3DController _controller = Flutter3DController();
  late final PageController _pageController;
  late int _index;
  bool _isRotating = false;
  String? _error;

  Bus3DModel get _current => widget.models[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.models.length - 1);
    _pageController = PageController(initialPage: _index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _isRotating = false;
      _error = null;
    });
  }

  void _toggleRotation() {
    if (_isRotating) {
      _controller.pauseRotation();
    } else {
      _controller.startRotation(rotationSpeed: 20);
    }
    setState(() => _isRotating = !_isRotating);
  }

  void _resetCamera() {
    _controller.resetCameraOrbit();
    _controller.resetCameraTarget();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.models.length > 1;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              _current.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasMultiple)
              Text(
                '${_index + 1} / ${widget.models.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Carrousel manuel par swipe
          if (hasMultiple)
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.models.length,
              itemBuilder: (context, index) {
                return _buildModelViewer(widget.models[index]);
              },
            )
          else
            _buildModelViewer(_current),

          // Overlay des boutons d'action (rotation et recentrer)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _error == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _overlayActionButton(
                            icon: _isRotating
                                ? Icons.pause_rounded
                                : Icons.threesixty_rounded,
                            label: _isRotating ? 'Pause' : 'Rotation',
                            onTap: _toggleRotation,
                          ),
                          const SizedBox(width: 12),
                          _overlayActionButton(
                            icon: Icons.center_focus_strong_rounded,
                            label: 'Recentrer',
                            onTap: _resetCamera,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Indicateur de page pour le carrousel
          if (hasMultiple && _error == null)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.models.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _index
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelViewer(Bus3DModel model) {
    if (_error != null && model.src == _current.src) {
      return _buildError();
    }
    return Flutter3DViewer(
      key: ValueKey(model.src),
      src: model.src,
      progressBarColor: const Color(0xFF00E676),
      controller: _controller,
      onError: (error) {
        if (!mounted) return;
        setState(() => _error = error);
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.view_in_ar_outlined,
              color: Colors.white38,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Modèle 3D indisponible',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que le fichier « ${_current.src} » existe '
              'et que vous avez une connexion internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E676), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}