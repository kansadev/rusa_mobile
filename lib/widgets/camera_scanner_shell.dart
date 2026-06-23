import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const Color _kCameraAccent = Color(0xFF00E676);

/// Enveloppe scanner : explication → demande système caméra → prévisualisation + erreurs.
class CameraScannerShell extends StatefulWidget {
  const CameraScannerShell({
    super.key,
    required this.controller,
    required this.onDetect,
    required this.permissionRationale,
    this.overlays = const [],
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final String permissionRationale;
  final List<Widget> overlays;

  @override
  State<CameraScannerShell> createState() => _CameraScannerShellState();
}

class _CameraScannerShellState extends State<CameraScannerShell> {
  bool _introAccepted = false;

  @override
  Widget build(BuildContext context) {
    if (!_introAccepted) {
      return _PermissionIntro(
        rationale: widget.permissionRationale,
        onContinue: () => setState(() => _introAccepted = true),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: widget.controller,
          onDetect: widget.onDetect,
          placeholderBuilder: (_) => const _ScannerPlaceholder(),
          errorBuilder: (context, error) => _ScannerErrorView(
            error: error,
            controller: widget.controller,
          ),
        ),
        ...widget.overlays,
      ],
    );
  }
}

class _PermissionIntro extends StatelessWidget {
  const _PermissionIntro({
    required this.rationale,
    required this.onContinue,
  });

  final String rationale;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121212),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _kCameraAccent,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Accès à la caméra',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rationale,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kCameraAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Autoriser la caméra',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF121212),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({
    required this.error,
    required this.controller,
  });

  final MobileScannerException error;
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: const Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.videocam_off_rounded : Icons.error_outline,
                color: denied ? Colors.orangeAccent : Colors.redAccent,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                denied
                    ? 'Permission caméra refusée'
                    : 'Caméra indisponible',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                denied
                    ? 'Autorisez l\'accès à la caméra dans les réglages de '
                        'l\'application pour scanner un QR code.'
                    : error.errorCode.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (denied) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async => controller.start(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ),
                TextButton(
                  onPressed: Geolocator.openAppSettings,
                  child: const Text('Ouvrir les réglages'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
